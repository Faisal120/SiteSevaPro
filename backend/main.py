"""Site Seva Pro - FastAPI backend (main app + V1 routes)."""
from __future__ import annotations

from services.design_service import design_service
from services.design_wallet_service import InsufficientCreditsError, design_wallet_service
from services.plan_catalog import PLAN_CATALOG, canonical_plan, plan_details
from models.auth import (
    Role,
    Plan,
    ApplicationOut,
)

from asyncio import tasks
import os
from pydoc import doc
import secrets
import site
import time
from datetime import datetime, timedelta, timezone
from typing import List, Literal, Optional


import cloudinary
import cloudinary.utils
from fastapi import APIRouter, Depends, FastAPI, File, HTTPException, Query, Request, UploadFile
from pydantic import BaseModel, EmailStr, Field
from starlette.middleware.cors import CORSMiddleware
from starlette.middleware.base import BaseHTTPMiddleware

from fastapi.responses import Response
from models.site import (
    SiteIn,
    SiteAssignmentIn,
)

from models.common import (
    MessageResponse,
    IdResponse,
)

from models.site import (
    SiteSummary,
    SiteDetail,
)

from api.labour import router as labour_router
from api.attendance import router as attendance_router
from api.dashboard import router as dashboard_router
from api.wallet import (
    router as wallet_router
)
from api.notifications import (
    router as notifications_router,
)
from api.reports import router as reports_router
from api.admin import (
router as admin_router
)

from api.design import router as design_router

from api.design_wallet import router as design_wallet_router
from api.launch import router as launch_router
from api.ai_assistant import router as ai_assistant_router
from api.whatsapp import router as whatsapp_router
from api.public import router as public_router
from services.ai_assistant_service import ai_assistant_service

# Shared infra — single source of truth for db, auth, helpers
from core import (
    db,
    mongo_client,
    logger,
    JWT_SECRET,
    JWT_ALGORITHM,
    SUPER_ADMIN_EMAIL,
    SUPER_ADMIN_PASSWORD,
    EMERGENT_LLM_KEY,
    now_iso,
    new_id,
    hash_password,
    verify_password,
    create_jwt,
    decode_jwt,
    get_current_user,
    require_roles,
)

from services.wallet_service import wallet_service
from services.access_control import require_site_access
from services.application_service import application_service
from services.account_security import (
    normalize_phone,
)
from services.outbound_notification_service import outbound_notification_service
from repositories.audit_repository import audit_repository

MAP_GENERATION_COST = 5

cloudinary.config(
    cloud_name=os.environ["CLOUDINARY_CLOUD_NAME"],
    api_key=os.environ["CLOUDINARY_API_KEY"],
    api_secret=os.environ["CLOUDINARY_API_SECRET"],
    secure=True,
)



def gen_username(company: str) -> str:
    slug = "".join(c.lower() for c in company if c.isalnum())[:10] or "user"
    return f"{slug}{secrets.randbelow(9000) + 1000}"

def gen_password() -> str:
    return "Site@" + secrets.token_urlsafe(6).replace("-", "x").replace("_", "y")


class NotificationIn(BaseModel):
    user_id: Optional[str] = None
    company_id: Optional[str] = None
    title: str
    body: str
    type: Literal["INFO", "PAYMENT", "STOCK", "ATTENDANCE", "SUBSCRIPTION", "SITE"] = "INFO"

class AIInsightIn(BaseModel):
    kind: Literal["material_estimate", "progress_summary", "delay_prediction", "expense_analysis"]
    context: dict

# -------- Auth dependencies are imported from core.py --------

def serialize_user(u: dict) -> dict:
    return {
        "id": u["id"],
        "email": u["email"],
        "username": u.get("username"),
        "role": u["role"],
        "full_name": u.get("full_name", ""),
        "company_id": u.get("company_id"),
        "company_name": u.get("company_name"),
        "plan": u.get("plan"),
        "site_ids": u.get("site_ids", []),
        "blocked": u.get("blocked", False),
        "created_at": u.get("created_at", now_iso()),
    }

def scope_query(user: dict, base: Optional[dict] = None) -> dict:
    q = dict(base or {})
    if user["role"] == "SUPER_ADMIN":
        return q
    if user["role"] == "CONTRACTOR":
        q["company_id"] = user["company_id"]
        return q
    if user["role"] == "SUPERVISOR":
        q["company_id"] = user["company_id"]
        q["site_id"] = {"$in": user.get("site_ids", [])}
        return q
    if user["role"] == "CLIENT":
        q["company_id"] = user["company_id"]
        q["client_email"] = user["email"]
        return q
    return q

# -------- App --------
ENVIRONMENT = os.getenv("APP_ENV", "development").strip().lower()
app = FastAPI(
    title="Site Seva Pro API",
    docs_url=None if ENVIRONMENT == "production" else "/docs",
    redoc_url=None if ENVIRONMENT == "production" else "/redoc",
    openapi_url=None if ENVIRONMENT == "production" else "/openapi.json",
)
api = APIRouter(prefix="/api")


class SecurityHeadersMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        response = await call_next(request)
        response.headers.setdefault("X-Content-Type-Options", "nosniff")
        response.headers.setdefault("X-Frame-Options", "DENY")
        response.headers.setdefault("Referrer-Policy", "strict-origin-when-cross-origin")
        response.headers.setdefault("Permissions-Policy", "camera=(), microphone=(), geolocation=()")
        if ENVIRONMENT == "production":
            response.headers.setdefault("Strict-Transport-Security", "max-age=31536000; includeSubDomains")
        return response


app.add_middleware(SecurityHeadersMiddleware)

@api.get("/")
async def root():
    return {"app": "Site Seva Pro", "status": "ok", "time": now_iso()}


@api.get("/health/live")
async def liveness():
    return {"status": "ok", "time": now_iso()}


@api.get("/health/ready")
async def readiness():
    try:
        await db.command("ping")
    except Exception as error:
        logger.warning("Readiness database check failed: %s", error)
        raise HTTPException(503, "Database is unavailable") from None
    return {"status": "ready", "database": "ok", "time": now_iso()}

# ---------- ADMIN ----------
@api.get("/admin/dashboard")
async def admin_stats(_: dict = Depends(require_roles("SUPER_ADMIN"))):
    total_contractors = await db.users.count_documents({"role": "CONTRACTOR"})
    active_sites = await db.sites.count_documents({"status": "ACTIVE"})
    pending_apps = await db.applications.count_documents({"status": "PENDING"})
    active_users = await db.users.count_documents({"blocked": {"$ne": True}})
    # Revenue trend from persisted subscription payments.
    subscription_payments = await db.payments.find(
        {"type": "SUBSCRIPTION"},
        {"_id": 0, "amount": 1, "date": 1, "created_at": 1},
    ).to_list(5000)
    revenue_by_month = {}
    for payment in subscription_payments:
        key = str(payment.get("date") or payment.get("created_at") or "")[:7]
        if key:
            revenue_by_month[key] = revenue_by_month.get(key, 0) + float(payment.get("amount") or 0)
    today = datetime.now(timezone.utc)
    months = []
    for offset in range(5, -1, -1):
        month_index = today.year * 12 + today.month - 1 - offset
        year, month_zero = divmod(month_index, 12)
        key = f"{year:04d}-{month_zero + 1:02d}"
        label = datetime(year, month_zero + 1, 1).strftime("%b")
        months.append({"month": label, "key": key, "revenue": revenue_by_month.get(key, 0)})
    monthly_revenue = revenue_by_month.get(today.strftime("%Y-%m"), 0)
    # Expiring subs
    soon = (datetime.now(timezone.utc) + timedelta(days=7)).isoformat()
    expiring = await db.subscriptions.count_documents({
        "status": "ACTIVE",
        "expires_at": {"$gte": today.isoformat(), "$lte": soon},
    })
    return {
        "total_contractors": total_contractors,
        "active_sites": active_sites,
        "pending_applications": pending_apps,
        "active_users": active_users,
        "monthly_revenue": monthly_revenue,
        "expiring_subscriptions": expiring,
        "revenue_trend": months,
    }

@api.get("/admin/applications", response_model=List[ApplicationOut])
async def list_applications(status_filter: Optional[str] = Query(None, alias="status"), _: dict = Depends(require_roles("SUPER_ADMIN"))):
    q = {}
    if status_filter:
        q["status"] = status_filter
    apps = await db.applications.find(q, {"_id": 0}).sort("created_at", -1).to_list(500)
    return apps

@api.post("/admin/applications/{app_id}/approve")
async def approve_application(
    app_id: str,
    admin: dict = Depends(require_roles("SUPER_ADMIN")),
):
    return await application_service.approve(app_id, reviewed_by=admin["id"])

@api.post("/admin/applications/{app_id}/reject")
async def reject_application(
    app_id: str,
    admin: dict = Depends(require_roles("SUPER_ADMIN")),
):
    return await application_service.reject(app_id, reviewed_by=admin["id"])

@api.get("/admin/contractors")
async def list_contractors(_: dict = Depends(require_roles("SUPER_ADMIN"))):
    users = await db.users.find({"role": "CONTRACTOR"}, {"_id": 0, "password_hash": 0}).sort("created_at", -1).to_list(500)
    return users

@api.get("/admin/supervisors")
async def list_supervisors(_: dict = Depends(require_roles("SUPER_ADMIN"))):
    users = await db.users.find({"role": "SUPERVISOR"}, {"_id": 0, "password_hash": 0}).sort("created_at", -1).to_list(500)
    # Enrich with site count
    for u in users:
        u["site_count"] = len(u.get("site_ids", []))
    return users

@api.get("/admin/subscriptions")
async def list_subscriptions(_: dict = Depends(require_roles("SUPER_ADMIN"))):
    subs = await db.subscriptions.find({}, {"_id": 0}).sort("started_at", -1).to_list(500)
    company_ids = [s["company_id"] for s in subs]
    companies = {c["id"]: c async for c in db.companies.find({"id": {"$in": company_ids}})}
    for s in subs:
        c = companies.get(s["company_id"]) or {}
        s["company_name"] = c.get("name")
    return subs

@api.post("/admin/contractors/{user_id}/block")
async def block_contractor(user_id: str, blocked: bool = True, _: dict = Depends(require_roles("SUPER_ADMIN"))):
    contractor = await db.users.find_one(
        {"id": user_id, "role": "CONTRACTOR"},
        {"_id": 0},
    )
    if not contractor:
        raise HTTPException(404, "Contractor not found")
    res = await db.users.update_one(
        {"id": user_id, "role": "CONTRACTOR"},
        {"$set": {"blocked": blocked, "status": "SUSPENDED" if blocked else "ACTIVE"}},
    )
    if res.matched_count == 0:
        raise HTTPException(404, "User not found")
    delivery = None
    if not blocked:
        delivery = await outbound_notification_service.send_approval(
            contractor,
            "Account activated",
            "Your SiteSeva Pro contractor account is active again.",
            event="CONTRACTOR_ACTIVATED",
        )
    return {"ok": True, "blocked": blocked, "whatsapp_delivery": delivery}

class TeamMemberIn(BaseModel):
    full_name: str = Field(min_length=2, max_length=120)
    email: EmailStr
    phone: str = Field(min_length=8, max_length=24)
    role: Literal["SUPERVISOR", "CLIENT"]

class SiteAssignmentIn(BaseModel):
    user_id: str

class WhatsAppNumberIn(BaseModel):
    phone: str = Field(min_length=8, max_length=24)

@api.get("/team")
async def list_team(user: dict = Depends(require_roles("CONTRACTOR"))):
    members = await db.users.find(
        {
            "company_id": user["company_id"],
            "role": {"$in": ["SUPERVISOR", "CLIENT"]},
            "archived_at": {"$exists": False},
        },
        {"_id": 0, "password_hash": 0}
    ).to_list(500)

    return members

@api.post("/team")
async def create_team_member(
    body: TeamMemberIn,
    user: dict = Depends(require_roles("CONTRACTOR"))
):

    existing = await db.users.find_one({
        "email": body.email.lower()
    })

    if existing:
        raise HTTPException(400, "Email already exists")

    try:
        phone = normalize_phone(body.phone)
    except ValueError as error:
        raise HTTPException(400, str(error)) from error

    doc = {
        "id": new_id(),
        "email": body.email.lower(),
        "phone": phone,
        "whatsapp": phone,
        "username": gen_username(body.full_name),
        "role": body.role,
        "full_name": body.full_name,
        "company_id": user["company_id"],
        "company_name": user["company_name"],
        "site_ids": [],
        "permissions": [],
        "blocked": False,
        "must_change_password": True,
        "password_setup_required": True,
        "password_setup_completed": False,
        "account_status": "PASSWORD_SETUP_REQUIRED",
        "password_version": 0,
        "created_at": now_iso(),
    }

    await db.users.insert_one(doc)
    doc.pop("_id", None)

    delivery = await outbound_notification_service.send_account_approved(doc)
    await db.users.update_one(
        {"id": doc["id"]},
        {
            "$set": {
                "credential_delivery_status": delivery.get("status"),
                "credential_delivery_id": delivery.get("id"),
            }
        },
    )
    await audit_repository.log("TEAM_ACCOUNT_CREATED", "Team member requires password setup", actor_id=user["id"], account_id=doc["id"], company_id=user["company_id"], outcome=delivery.get("status", "UNKNOWN"))

    return {
        "success": True,
        "member": {
            key: value for key, value in doc.items() if key != "password_hash"
        },
        "whatsapp_delivery": delivery,
    }


@api.post("/team/{user_id}/resend-credentials")
async def resend_team_credentials(
    user_id: str,
    user: dict = Depends(require_roles("CONTRACTOR")),
):
    member = await db.users.find_one(
        {
            "id": user_id,
            "company_id": user["company_id"],
            "role": {"$in": ["SUPERVISOR", "CLIENT"]},
            "archived_at": {"$exists": False},
        },
        {"_id": 0},
    )
    if not member:
        raise HTTPException(404, "Team member not found")
    if not member.get("password_setup_required"):
        return {"success": False, "status": "ACTIVE", "message": "Ask the member to use Forgot password. Their password was not changed."}
    delivery = await outbound_notification_service.send_account_approved(member)
    await db.users.update_one(
        {"id": member["id"]},
        {
            "$set": {
                "credential_delivery_status": delivery.get("status"),
                "credential_delivery_id": delivery.get("id"),
                "credentials_resent_at": now_iso(),
            }
        },
    )
    await audit_repository.log("TEAM_RESEND_ACTIVATION_NOTIFICATION", "Activation notification resent", actor_id=user["id"], account_id=member["id"], company_id=user["company_id"], outcome=delivery.get("status", "UNKNOWN"))
    return {"success": True, "whatsapp_delivery": delivery}


@api.patch("/team/{user_id}/whatsapp")
async def update_team_whatsapp(
    user_id: str,
    body: WhatsAppNumberIn,
    user: dict = Depends(require_roles("CONTRACTOR")),
):
    try:
        phone = normalize_phone(body.phone)
    except ValueError as error:
        raise HTTPException(400, str(error)) from error
    result = await db.users.update_one(
        {
            "id": user_id,
            "company_id": user["company_id"],
            "role": {"$in": ["SUPERVISOR", "CLIENT"]},
            "archived_at": {"$exists": False},
        },
        {"$set": {"phone": phone, "whatsapp": phone, "updated_at": now_iso()}},
    )
    if result.matched_count == 0:
        raise HTTPException(404, "Team member not found")
    return {"success": True, "phone": phone}

@api.delete("/team/{user_id}")
async def delete_team_member(
    user_id: str,
    user: dict = Depends(require_roles("CONTRACTOR"))
):
    result = await db.users.update_one({
        "id": user_id,
        "company_id": user["company_id"],
        "role": {"$in": ["SUPERVISOR", "CLIENT"]},
    }, {"$set": {"blocked": True, "archived_at": now_iso()}})

    if result.matched_count == 0:
        raise HTTPException(404, "Team member not found")

    return {"success": True}

@api.patch("/team/{user_id}")
async def toggle_team_member(
    user_id: str,
    blocked: bool,
    user: dict = Depends(require_roles("CONTRACTOR"))
):

    result = await db.users.update_one(
        {
            "id": user_id,
            "company_id": user["company_id"],
            "role": {"$in": ["SUPERVISOR", "CLIENT"]},
        },
        {
            "$set": {
                "blocked": blocked
            }
        }
    )

    if result.matched_count == 0:
        raise HTTPException(404, "Team member not found")

    return {
        "success": True,
        "blocked": blocked
    }


# ---------- SITE TASKS ----------

class TaskStatusIn(BaseModel):
    completed: bool = True

@api.get("/site-tasks/{site_id}")
async def get_site_tasks(
    site_id: str,
    user: dict = Depends(get_current_user)
):

    await require_site_access(site_id, user)

    return await db.site_tasks.find(
        {"site_id": site_id, "company_id": user["company_id"]},
        {"_id": 0}
    ).to_list(500)
    
async def recalculate_site_progress(site_id):

    tasks = await db.site_tasks.find(
        {"site_id": site_id}
    ).to_list(500)

    if not tasks:
        return

    total = sum(
        t.get("weight", 0)
        for t in tasks
    )

    completed = sum(
        t.get("weight", 0)
        for t in tasks
        if t.get("completed")
    )

    progress = round(
        (completed / total) * 100
    )

    await db.sites.update_one(
        {"id": site_id},
        {
            "$set": {
                "progress": progress
            }
        }
    )
    
@api.post("/site-tasks/{task_id}/complete")
async def complete_task(
    task_id: str,
    user = Depends(
        require_roles(
            "CONTRACTOR",
            "SUPERVISOR"
        )
    )
):
    task = await db.site_tasks.find_one(
        {"id": task_id, "company_id": user["company_id"]}
    )

    if not task:
        raise HTTPException(
            status_code=404,
            detail="Task not found"
        )

    await require_site_access(task["site_id"], user, write=True)

    await db.site_tasks.update_one(
        {"id": task_id, "company_id": user["company_id"]},
        {
            "$set": {
                "completed": True
            }
        }
    )

    site_id = task["site_id"]

    await recalculate_site_progress(site_id)
    updated_site = await db.sites.find_one(
        {"id": site_id, "company_id": user["company_id"]},
        {"_id": 0, "progress": 1},
    )
    progress = (updated_site or {}).get("progress", 0)

    return {
        "success": True,
        "progress": progress
    }
    
@api.post("/branding/logo")
async def upload_logo(
    file: UploadFile = File(...),
    user: dict = Depends(
        require_roles("CONTRACTOR")
    )
):

    result = cloudinary.uploader.upload(
        file.file,
        folder="siteseva/company_logos"
    )

    logo_url = result["secure_url"]

    await db.companies.update_one(
        {
            "id": user["company_id"]
        },
        {
            "$set": {
                "branding.logo_url":
                logo_url
            }
        }
    )
    
    return {
        "logo_url": logo_url
    }

class BrandingIn(BaseModel):
    company_name:str=""
    gst_number:str=""
    company_address:str=""
    phone:str=""
    website:str=""
    email:str=""
    logo_url:str=""

@api.get("/branding")
async def get_branding(
    user: dict = Depends(get_current_user)
):

    company_id = user.get("company_id")
    if not company_id:
        return {
            "company_name": "SiteSeva Pro",
            "email": user.get("email", ""),
        }

    company = await db.companies.find_one(
        {
            "id": company_id
        }
    )

    return (company or {}).get(
        "branding",
        {}
    )


@api.put("/branding")
async def save_branding(
    body: BrandingIn,
    user: dict = Depends(
        require_roles("CONTRACTOR")
    )
):

    await db.companies.update_one(
        {
            "id": user["company_id"]
        },
        {
            "$set": {
                "branding":
                body.model_dump()
            }
        }
    )

    return {
        "success": True
    }
    
class FloorRequirementIn(BaseModel):
    """A concise, floor-specific brief for the architectural planner."""

    floor_number: int
    bedrooms: int = 2
    bathrooms: int = 2
    living: bool = True
    dining: bool = True
    kitchen: bool = True
    staircase: bool = True
    parking: bool = False
    balcony: bool = False
    pooja_room: bool = False
    study_room: bool = False
    store_room: bool = False
    utility_room: bool = False
    lift: bool = False


class MapRequestIn(BaseModel):

    site_id: str

    project_name: str = "Untitled Project"

    plot_width: float
    plot_length: float

    facing: str

    bedrooms: int
    bathrooms: int
    floors: int = 1

    type: str = "2D"
    variation: int = 0

    parking: bool = False
    balcony: bool = False
    living: bool = True
    dining: bool = True
    kitchen: bool = True
    pooja_room: bool = False
    study_room: bool = False
    store_room: bool = False
    utility_room: bool = False
    lift: bool = False
    staircase: bool = True
    garden: bool = False
    floor_requirements: list[FloorRequirementIn] = []

    @property
    def design_type(self):
        return self.type
    

@api.get("/maps")
async def get_maps(
    user: dict = Depends(
        require_roles("CONTRACTOR")
    )
):

    return await db.map_requests.find(
        {
            "company_id":
            user["company_id"]
        },
        {
            "_id": 0
        }
    ).sort(
        "created_at",
        -1
    ).to_list(500)

@app.post("/api/maps/generate")
async def generate_map(
    body: MapRequestIn,
    user: dict = Depends(get_current_user),
):

    try:
        design = await design_service.create(
            user,
            body,
        )
    except InsufficientCreditsError as error:
        raise HTTPException(status_code=402, detail=str(error))

    return design

@app.post("/api/maps/{design_id}/3d/{floor_number}")
async def generate_3d_map(design_id: str, floor_number: int, user: dict = Depends(get_current_user)):
    try:
        return await design_service.generate_3d(user, design_id, floor_number)
    except InsufficientCreditsError as error:
        raise HTTPException(status_code=402, detail=str(error))
    except ValueError as error:
        raise HTTPException(status_code=400, detail=str(error))


@app.post("/api/maps/{design_id}/technical/{drawing_type}")
async def generate_technical_map(
    design_id: str,
    drawing_type: str,
    user: dict = Depends(get_current_user),
):
    """Generate a billable technical overlay from an approved 2D plan."""
    try:
        return await design_service.create_technical_drawing(
            user,
            design_id,
            drawing_type,
        )
    except InsufficientCreditsError as error:
        raise HTTPException(status_code=402, detail=str(error))
    except ValueError as error:
        raise HTTPException(status_code=400, detail=str(error))


@app.get("/api/maps/{design_id}/download/{drawing_type}.pdf")
async def download_pdf_drawing(
    design_id: str,
    drawing_type: str,
    floor_number: int = 1,
    user: dict = Depends(get_current_user),
):
    try:
        pdf = await design_service.get_pdf_drawing(user, design_id, drawing_type, floor_number)
    except ValueError as error:
        raise HTTPException(status_code=400, detail=str(error))

    return Response(
        content=pdf,
        media_type="application/pdf",
        headers={
            "Content-Disposition": f'attachment; filename="siteseva-{drawing_type.lower()}-floor-{floor_number}-{design_id}.pdf"',
        },
    )
    
@api.get("/plans/{plan_id}")
async def get_plan(
    plan_id: str,
    user: dict = Depends(
        require_roles("CONTRACTOR")
    )
):

    plan = await db.floor_plans.find_one(
        {
            "id": plan_id,
            "company_id": user["company_id"]
        },
        {
            "_id": 0
        }
    )

    if not plan:
        raise HTTPException(
            404,
            "Plan not found"
        )

    return plan

@api.get("/plans")
async def get_all_plans(
    user: dict = Depends(
        require_roles("CONTRACTOR")
    )
):

    return await db.floor_plans.find(
        {
            "company_id":
            user["company_id"]
        },
        {
            "_id": 0
        }
    ).sort(
        "created_at",
        -1
    ).to_list(100)
    


# ---------- SUBSCRIPTIONS ----------
SUBSCRIPTION_CATALOG = tuple({**details, "currency": "INR", "billing_cycle": "MONTHLY"} for details in PLAN_CATALOG.values())


@api.get("/subscription/plans")
async def subscription_plans(_: dict = Depends(get_current_user)):
    """Return the commercial subscription catalog, not customer floor plans."""
    return SUBSCRIPTION_CATALOG


@api.get("/subscription")
async def my_subscription(user: dict = Depends(get_current_user)):
    sub = await db.subscriptions.find_one({"company_id": user["company_id"]}, {"_id": 0})
    return sub or {"plan": "FREE", "status": "ACTIVE"}

@api.get("/subscription/current")
async def current_subscription(user: dict = Depends(get_current_user)):
    """Canonical mobile subscription payload without guessed renewal values."""
    sub = await db.subscriptions.find_one({"company_id": user["company_id"]}, {"_id": 0})
    if not sub:
        return {"plan": user.get("plan", "FREE"), "status": "ACTIVE"}
    return {
        "plan": sub.get("plan", user.get("plan", "FREE")),
        "status": sub.get("status", "ACTIVE"),
        "renews_at": sub.get("expires_at"),
        "started_at": sub.get("started_at"),
    }

@api.post("/subscription/renewal/request")
async def request_subscription_renewal(user: dict = Depends(require_roles("CONTRACTOR"))):
    """Creates one verifiable renewal request; payment approval remains server-admin controlled."""
    existing = await db.subscription_renewal_requests.find_one({
        "company_id": user["company_id"], "status": "PENDING"
    }, {"_id": 0})
    if existing:
        return existing
    subscription = await db.subscriptions.find_one({"company_id": user["company_id"]}, {"_id": 0}) or {}
    request = {
        "id": new_id(), "company_id": user["company_id"], "user_id": user["id"],
        "plan": subscription.get("plan", user.get("plan", "FREE")),
        "status": "PENDING", "created_at": now_iso(),
    }
    await db.subscription_renewal_requests.insert_one(dict(request))
    await db.notifications.insert_one({
        "id": new_id(), "company_id": user["company_id"], "user_id": user["id"],
        "title": "Subscription renewal requested",
        "body": "Your renewal request is pending payment verification.",
        "type": "SUBSCRIPTION", "read": False, "created_at": now_iso(),
    })
    return request

@api.post("/subscription/upgrade")
async def upgrade_subscription(plan: Plan, user: dict = Depends(require_roles("CONTRACTOR"))):
    if plan != "FREE":
        raise HTTPException(
            status_code=400,
            detail="Paid plans must be activated through /api/payment/request and admin verification.",
        )
    amounts = {"FREE": 0, "PREMIUM": 2999, "ENTERPRISE": 4999}
    amount = amounts.get(plan, 0)
    expires = (datetime.now(timezone.utc) + timedelta(days=30)).isoformat()
    await db.subscriptions.update_one(
        {"company_id": user["company_id"]},
        {"$set": {
            "id": new_id(), "company_id": user["company_id"], "plan": plan, "status": "ACTIVE",
            "started_at": now_iso(), "expires_at": expires, "amount": amount,
        }},
        upsert=True,
    )
    await db.users.update_one({"id": user["id"]}, {"$set": {"plan": plan}})
    if plan in ("PREMIUM", "PRO", "ENTERPRISE"):
        credits = plan_details(plan)["monthly_design_credits"]
        await design_wallet_service.balance(user["company_id"])
        await design_wallet_service.add(user["company_id"], credits, f"{plan} subscription credits")
    if amount > 0:
        await db.payments.insert_one({
            "id": new_id(), "company_id": user["company_id"], "site_id": None,
            "type": "SUBSCRIPTION", "amount": amount, "description": f"{plan} plan subscription",
            "date": now_iso()[:10], "created_at": now_iso(),
        })
    await db.notifications.insert_one({
        "id": new_id(), "company_id": user["company_id"], "user_id": user["id"],
        "title": "Subscription upgraded",
        "body": f"You're now on the {plan} plan. Expires {expires[:10]}.",
        "type": "SUBSCRIPTION", "read": False, "created_at": now_iso(),
    })
    return {"ok": True, "plan": plan, "amount": amount, "expires_at": expires}

# ---------- CLOUDINARY ----------
@api.get("/cloudinary/signature")
async def cloudinary_signature(
    resource_type: str = Query("image", pattern="^(image|video|raw)$"),
    folder: str = Query("siteseva/uploads"),
    user: dict = Depends(get_current_user),
):
    if not folder.startswith("siteseva/"):
        folder = "siteseva/" + folder
    timestamp = int(time.time())
    params = {"timestamp": timestamp, "folder": folder}
    signature = cloudinary.utils.api_sign_request(params, os.environ["CLOUDINARY_API_SECRET"])
    return {
        "signature": signature,
        "timestamp": timestamp,
        "cloud_name": os.environ["CLOUDINARY_CLOUD_NAME"],
        "api_key": os.environ["CLOUDINARY_API_KEY"],
        "folder": folder,
        "resource_type": resource_type,
    }

# ---------- AI INSIGHTS ----------
@api.post("/ai/insight")
async def ai_insight(body: AIInsightIn, user: dict = Depends(require_roles("CONTRACTOR", "SUPER_ADMIN"))):
    if user["role"] == "CONTRACTOR":
        subscription = await db.subscriptions.find_one({"company_id": user["company_id"], "status": "ACTIVE"}, {"_id": 0, "plan": 1})
        if (subscription or {}).get("plan") != "ENTERPRISE":
            raise HTTPException(403, "AI Insights are available on the Enterprise plan.")
    reply = await ai_assistant_service.generate_insight(
        body.kind,
        body.context,
        user,
    )
    return {"kind": body.kind, "insight": reply, "generated_at": now_iso()}

# ---------- MOUNT ----------
app.include_router(api)

from api.auth import router as auth_router
from api.site import router as sites_router
from api.tasks import router as tasks_router
from api.materials import router as materials_router
from api.payments import router as payments_router

app.include_router(auth_router)
app.include_router(sites_router)
app.include_router(tasks_router)
app.include_router(reports_router)
app.include_router(materials_router)
app.include_router(payments_router)

# V2 Phase A routes
from v2 import v2_router  # noqa: E402
app.include_router(v2_router)
app.add_middleware(
    CORSMiddleware,
    allow_credentials=True,
    allow_origins=[origin.strip() for origin in os.environ.get(
        "CORS_ORIGINS",
        "http://localhost:3000,http://127.0.0.1:3000,https://sitesevapro.in,https://www.sitesevapro.in",
    ).split(",") if origin.strip()],
    allow_methods=["*"],
    allow_headers=["*"],
)



app.include_router(
    attendance_router
)

app.include_router(
    dashboard_router
)

app.include_router(
    wallet_router
)

app.include_router(
    notifications_router
)

app.include_router(
    admin_router
)

app.include_router(
    labour_router
)

app.include_router(
    design_router
)

app.include_router(
    design_wallet_router
)

app.include_router(
    launch_router
)

app.include_router(ai_assistant_router)
app.include_router(whatsapp_router)
app.include_router(public_router)

@app.on_event("startup")
async def on_start():
    try:
        if ENVIRONMENT == "production":
            required = ["MONGO_URL", "JWT_SECRET", "SUPER_ADMIN_EMAIL", "SUPER_ADMIN_PASSWORD", "CLOUDINARY_CLOUD_NAME", "CLOUDINARY_API_KEY", "CLOUDINARY_API_SECRET", "CORS_ORIGINS", "FRONTEND_URL", "PASSWORD_RESET_SECRET"]
            missing = [key for key in required if not os.getenv(key) or "CHANGE_" in os.getenv(key, "") or "example.com" in os.getenv(key, "")]
            if missing:
                raise RuntimeError(f"Production configuration is incomplete: {', '.join(missing)}")
        await db.command("ping")
        admin_email = SUPER_ADMIN_EMAIL.lower().strip()
        admin_phone = None
        if os.getenv("SUPER_ADMIN_PHONE"):
            try:
                admin_phone = normalize_phone(os.environ["SUPER_ADMIN_PHONE"])
            except ValueError:
                logger.warning("SUPER_ADMIN_PHONE is not a valid WhatsApp number")
        existing = await db.users.find_one({"email": admin_email}, {"_id": 0, "id": 1})
        if not existing:
            await db.users.insert_one({
                "id": new_id(),
                "email": admin_email,
                "username": "superadmin",
                "password_hash": hash_password(SUPER_ADMIN_PASSWORD),
                "role": "SUPER_ADMIN",
                "full_name": "SiteSeva Super Admin",
                "company_id": None,
                "company_name": "SiteSeva Pro",
                "plan": "ENTERPRISE",
                "site_ids": [],
                "blocked": False,
                "must_change_password": False,
                "password_version": 0,
                "phone": admin_phone,
                "whatsapp": admin_phone,
                "created_at": now_iso(),
            })
            logger.info("Super admin account provisioned")
        elif admin_phone:
            await db.users.update_one(
                {"id": existing["id"]},
                {"$set": {"phone": admin_phone, "whatsapp": admin_phone}},
            )
        await db.users.create_index("email", unique=True)
        await db.users.create_index("id", unique=True)
        await db.sites.create_index([("company_id", 1), ("id", 1)], unique=True)
        await db.push_devices.create_index("token", unique=True)
        await db.push_devices.create_index([("company_id", 1), ("user_id", 1)])
        await db.notifications.create_index([("company_id", 1), ("created_at", -1)])
        await db.applications.create_index("id", unique=True)
        await db.outbound_notifications.create_index(
            "id",
            unique=True,
            partialFilterExpression={"id": {"$type": "string"}},
        )
        await db.outbound_notifications.create_index(
            "provider_message_id",
            sparse=True,
        )
        await db.password_reset_codes.create_index(
            [("user_id", 1), ("created_epoch", -1)]
        )
        await db.password_reset_codes.create_index(
            "purge_at",
            expireAfterSeconds=0,
        )
        await db.auth_challenges.create_index("id", unique=True)
        await db.auth_challenges.create_index([("user_id", 1), ("purpose", 1), ("created_epoch", -1)])
        await db.auth_challenges.create_index("purge_at", expireAfterSeconds=0)
        await db.outbound_notifications.create_index("dedupe_key", unique=True, sparse=True)
        await db.rate_limit_events.create_index("purge_at", expireAfterSeconds=0)
        await db.rate_limit_events.create_index([("key", 1), ("created_epoch", 1)])
    except Exception:
        logger.exception("Startup provisioning failed")
        if ENVIRONMENT == "production":
            raise

@app.on_event("shutdown")
async def on_stop():
    mongo_client.close()
