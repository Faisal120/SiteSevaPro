"""Site Seva Pro - FastAPI backend (main app + V1 routes)."""
from __future__ import annotations

from services.design_service import design_service
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
from fastapi import APIRouter, Depends, FastAPI, File, HTTPException, Query, UploadFile
from pydantic import BaseModel, EmailStr, Field
from starlette.middleware.cors import CORSMiddleware
from services.gemini_floorplanner import generate_floor_plan
from services.openai_floorplanner import (
    generate_floorplan_image
)

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

from api.branding import router as branding_router

from api.design_wallet import router as design_wallet_router

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
app = FastAPI(title="Site Seva Pro API")
api = APIRouter(prefix="/api")

@api.get("/")
async def root():
    return {"app": "Site Seva Pro", "status": "ok", "time": now_iso()}

# ---------- ADMIN ----------
@api.get("/admin/dashboard")
async def admin_stats(_: dict = Depends(require_roles("SUPER_ADMIN"))):
    total_contractors = await db.users.count_documents({"role": "CONTRACTOR"})
    active_sites = await db.sites.count_documents({"status": "ACTIVE"})
    pending_apps = await db.applications.count_documents({"status": "PENDING"})
    active_users = await db.users.count_documents({"blocked": {"$ne": True}})
    # Revenue: sum of subscription payments
    pipeline = [{"$match": {"type": "SUBSCRIPTION"}}, {"$group": {"_id": None, "total": {"$sum": "$amount"}}}]
    rev = await db.payments.aggregate(pipeline).to_list(1)
    monthly_revenue = rev[0]["total"] if rev else 0
    # Expiring subs
    soon = (datetime.now(timezone.utc) + timedelta(days=7)).isoformat()
    expiring = await db.subscriptions.count_documents({"expires_at": {"$lte": soon}})
    months = [
    {"month":"Jan","revenue":0},
    {"month":"Feb","revenue":0},
    {"month":"Mar","revenue":0},
]
    # Revenue trend (last 6 months mocked aggregate)
    # months = []
    # for i in range(5, -1, -1):
    #     dt = datetime.now(timezone.utc) - timedelta(days=30 * i)
    #     label = dt.strftime("%b")
    #     months.append({"month": label, "revenue": int(50000 + secrets.randbelow(80000))})
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
async def approve_application(app_id: str, _: dict = Depends(require_roles("SUPER_ADMIN"))):
    application = await db.applications.find_one({"id": app_id}, {"_id": 0})
    if not application:
        raise HTTPException(404, "Application not found")
    if application["status"] != "PENDING":
        raise HTTPException(400, "Already processed")
    username = gen_username(application["company_name"])
    password = gen_password()
    company_id = new_id()
    user_id = new_id()
    company = {
        "id": company_id,
        "name": application["company_name"],
        "owner_id": user_id,
        "gst_number": application.get("gst_number"),
        "city": application["city"],
        "state": application["state"],
        "address": application["office_address"],
        "created_at": now_iso(),
    }
    await db.companies.insert_one(dict(company))
    user = {
        "id": user_id,
        "email": application["email"],
        "username": username,
        "password_hash": hash_password(password),
        "role": "CONTRACTOR",
        "full_name": application["owner_name"],
        "company_id": company_id,
        "company_name": application["company_name"],
        "plan": "FREE",
        "site_ids": [],
        "blocked": False,
        "created_at": now_iso(),
    }
    await db.users.insert_one(dict(user))
    sub = {
        "id": new_id(),
        "company_id": company_id,
        "plan": "FREE",
        "status": "ACTIVE",
        "started_at": now_iso(),
        "expires_at": (datetime.now(timezone.utc) + timedelta(days=365)).isoformat(),
    }
    await db.subscriptions.insert_one(dict(sub))
    
    await db.applications.update_one({"id": app_id}, {"$set": {"status": "APPROVED", "approved_at": now_iso(), "user_id": user_id}})
    await db.notifications.insert_one({
        "id": new_id(), "user_id": user_id, "company_id": company_id,
        "title": "Welcome to Site Seva Pro",
        "body": f"Your account has been approved. Username: {username}",
        "type": "INFO", "read": False, "created_at": now_iso(),
    })
    return {"username": username, "password": password, "email": application["email"], "user_id": user_id}

@api.post("/admin/applications/{app_id}/reject")
async def reject_application(app_id: str, _: dict = Depends(require_roles("SUPER_ADMIN"))):
    res = await db.applications.update_one({"id": app_id, "status": "PENDING"}, {"$set": {"status": "REJECTED", "rejected_at": now_iso()}})
    if res.matched_count == 0:
        raise HTTPException(404, "Application not pending")
    return {"ok": True}

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
    res = await db.users.update_one({"id": user_id}, {"$set": {"blocked": blocked}})
    if res.matched_count == 0:
        raise HTTPException(404, "User not found")
    return {"ok": True, "blocked": blocked}

class TeamMemberIn(BaseModel):
    full_name: str
    email: EmailStr
    role: Literal["SUPERVISOR", "CLIENT"]

class SiteAssignmentIn(BaseModel):
    user_id: str

@api.get("/team")
async def list_team(user: dict = Depends(require_roles("CONTRACTOR"))):
    members = await db.users.find(
        {
            "company_id": user["company_id"],
            "role": {"$in": ["SUPERVISOR", "CLIENT"]}
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

    password = gen_password()

    doc = {
        "id": new_id(),
        "email": body.email.lower(),
        "username": gen_username(body.full_name),
        "password_hash": hash_password(password),
        "role": body.role,
        "full_name": body.full_name,
        "company_id": user["company_id"],
        "company_name": user["company_name"],
        "site_ids": [],
        "permissions": [],
        "blocked": False,
        "created_at": now_iso(),
    }

    await db.users.insert_one(doc)

    return {
        "success": True,
        "email": doc["email"],
        "password": password
    }

@api.delete("/team/{user_id}")
async def delete_team_member(
    user_id: str,
    user: dict = Depends(require_roles("CONTRACTOR"))
):
    await db.users.delete_one({
        "id": user_id,
        "company_id": user["company_id"]
    })

    return {"success": True}

@api.patch("/team/{user_id}")
async def toggle_team_member(
    user_id: str,
    blocked: bool,
    user: dict = Depends(require_roles("CONTRACTOR"))
):

    await db.users.update_one(
        {
            "id": user_id,
            "company_id": user["company_id"]
        },
        {
            "$set": {
                "blocked": blocked
            }
        }
    )

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

    return await db.site_tasks.find(
        {"site_id": site_id},
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
    print("CURRENT USER =", user)

    task = await db.site_tasks.find_one(
        {"id": task_id}
    )

    if not task:
        raise HTTPException(
            status_code=404,
            detail="Task not found"
        )

    await db.site_tasks.update_one(
        {"id": task_id},
        {
            "$set": {
                "completed": True
            }
        }
    )

    site_id = task["site_id"]

    completed = await db.site_tasks.count_documents({
        "site_id": site_id,
        "completed": True
    })

    total = await db.site_tasks.count_documents({
        "site_id": site_id
    })

    progress = 0

    if total > 0:
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
    user: dict = Depends(
        require_roles("CONTRACTOR")
    )
):

    company = await db.companies.find_one(
        {
            "id": user["company_id"]
        }
    )

    return company.get(
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
    
class MapRequestIn(BaseModel):

    site_id: str

    plot_width: float

    plot_length: float

    facing: str

    bedrooms: int

    bathrooms: int

    floors: int

    type: str = "2D"
    

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

@api.get("/test-openai")
async def test_openai():

    image = generate_floorplan_image({

        "plot_width":30,

        "plot_length":50,

        "bedrooms":3,

        "bathrooms":2,

        "floors":1,

        "facing":"East"

    })

    return Response(
        content=image,
        media_type="image/png"
    )
    
@api.post("/maps/generate")
async def generate_map(
    body: MapRequestIn,
    user: dict = Depends(require_roles("CONTRACTOR"))
):

    subscription = await db.subscriptions.find_one({
        "company_id": user["company_id"]
    })

    current_plan = (
        subscription or {}
    ).get(
        "plan",
        "FREE"
    )

    if current_plan == "FREE":
        raise HTTPException(
            403,
            "Upgrade required"
        )

    if body.type == "3D" and current_plan != "ENTERPRISE":
        raise HTTPException(
            403,
            "3D available only in Pro Plus"
        )

    

    site = await db.sites.find_one(
        {
            "id": body.site_id
        },
        {
            "_id": 0
        }
    )

    if not site:
        raise HTTPException(
            404,
            "Site not found"
        )

    design = await design_service.create(
    user,
    body,
    )

    return design
    
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
@api.get("/subscription")
async def my_subscription(user: dict = Depends(require_roles("CONTRACTOR"))):
    sub = await db.subscriptions.find_one({"company_id": user["company_id"]}, {"_id": 0})
    return sub or {"plan": "FREE", "status": "ACTIVE"}

@api.post("/subscription/upgrade")
async def upgrade_subscription(plan: Plan, user: dict = Depends(require_roles("CONTRACTOR"))):
    amounts = {"FREE": 0, "PREMIUM": 899, "ENTERPRISE": 1899}
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
    try:
        from emergentintegrations.llm.chat import LlmChat, UserMessage
    except ImportError:
        raise HTTPException(500, "AI library not installed")
    if not EMERGENT_LLM_KEY:
        raise HTTPException(500, "AI key not configured")
    prompts = {
        "material_estimate": "You are a construction quantity surveyor. Given the site context, estimate required materials with quantities (cement bags, steel kg, sand cft, bricks count, tiles sqft). Be concise and use bullet points.",
        "progress_summary": "You are a construction project manager. Summarize site progress, milestones reached, blockers, and next 7-day plan in clear bullets.",
        "delay_prediction": "You are a project risk analyst. Predict potential delays for this construction site based on the context. List top 3 risks with likelihood and mitigation.",
        "expense_analysis": "You are a construction CFO. Analyze the expense breakdown and suggest 3 cost optimization tactics. Use bullets and concrete numbers when possible.",
    }
    system = prompts[body.kind]
    chat = LlmChat(
        api_key=EMERGENT_LLM_KEY,
        session_id=f"siteseva-{body.kind}-{user['id']}",
        system_message=system,
    ).with_model("anthropic", "claude-sonnet-4-5-20250929")
    msg = UserMessage(text=f"Context:\n{body.context}\n\nProvide your insight now.")
    reply: str = ""
    try:
        reply = await chat.send_message(msg)
    except Exception as e:
        logger.exception("AI error")
        raise HTTPException(502, f"AI service error: {e}") from e
    return {"kind": body.kind, "insight": reply, "generated_at": now_iso()}

# ---------- MOUNT ----------
app.include_router(api)

from api.auth import router as auth_router
from api.site import router as sites_router
from api.tasks import router as tasks_router
from api.reports import router as reports_router
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
    allow_origins=os.environ.get("CORS_ORIGINS", "*").split(","),
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
    reports_router
)

app.include_router(
    labour_router
)

app.include_router(
    design_router
)

app.include_router(
    branding_router
)

app.include_router(
    design_wallet_router
)

@app.on_event("startup")
async def on_start():
    try:
        pass
    except Exception:
        logger.exception("Seed failed")

@app.on_event("shutdown")
async def on_stop():
    mongo_client.close()
