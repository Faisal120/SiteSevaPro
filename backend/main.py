"""Site Seva Pro - FastAPI backend (main app + V1 routes)."""
from __future__ import annotations

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
from services.svg_generator import generate_floor_svg
from services.plan_generator import generate_plan

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


# -------- Models --------
Role = Literal["SUPER_ADMIN", "CONTRACTOR", "SUPERVISOR", "CLIENT"]
Plan = Literal["FREE", "PREMIUM", "ENTERPRISE"]

class UserOut(BaseModel):
    id: str
    email: EmailStr
    username: Optional[str] = None
    role: Role
    full_name: str
    company_id: Optional[str] = None
    company_name: Optional[str] = None
    plan: Optional[Plan] = None
    site_ids: List[str] = []
    blocked: bool = False
    created_at: str

class LoginIn(BaseModel):
    email: EmailStr
    password: str

class TokenOut(BaseModel):
    token: str
    user: UserOut

class RegisterApplicationIn(BaseModel):
    company_name: str
    owner_name: str
    mobile: str
    email: EmailStr
    gst_number: Optional[str] = None
    office_address: str
    city: str
    state: str
    active_projects: int = 0
    employee_count: int = 0

class ApplicationOut(BaseModel):
    id: str
    company_name: str
    owner_name: str
    mobile: str
    email: EmailStr
    gst_number: Optional[str] = None
    office_address: str
    city: str
    state: str
    active_projects: int
    employee_count: int
    status: Literal["PENDING", "APPROVED", "REJECTED"]
    created_at: str

class SiteIn(BaseModel):
    name: str
    location: str
    budget: float
    start_date: str
    end_date: str
    status: Literal["PLANNING","ACTIVE","ON_HOLD","COMPLETED"] = "ACTIVE"
    progress: int = 0
    description: Optional[str] = None
    supervisor_ids: List[str] = []
    client_id: Optional[str] = None
    cover_image: Optional[str] = None
    floors: int = 1
    has_boring: bool = False
    has_septic_tank: bool = True
    has_soak_pit: bool = True
    has_mumty: bool = True

class LabourIn(BaseModel):
    site_id: str
    name: str
    role: str
    daily_wage: float
    mobile: Optional[str] = None
    aadhaar: Optional[str] = None

class AttendanceIn(BaseModel):
    site_id: str
    date: str  # YYYY-MM-DD
    entries: List[dict]  # [{labour_id, status: PRESENT|HALF|ABSENT, present?: bool (legacy), overtime_hours, advance}]

class MaterialIn(BaseModel):
    site_id: str
    name: str
    category: Literal["Cement", "Steel", "Sand", "Bricks", "Electrical", "Plumbing", "Tiles", "Paint", "Other"]
    unit: str
    stock: float = 0
    low_stock_threshold: float = 10
    rate: float = 0

class MaterialTxnIn(BaseModel):
    material_id: str
    site_id: str
    type: Literal["INWARD", "OUTWARD"]
    quantity: float
    rate: Optional[float] = None
    vendor: Optional[str] = None
    note: Optional[str] = None
    invoice_url: Optional[str] = None

class PaymentIn(BaseModel):
    site_id: str
    type: Literal["CLIENT_RECEIVED", "EXPENSE", "LABOUR", "MATERIAL"]
    amount: float
    description: str
    date: str
    party: Optional[str] = None
    invoice_url: Optional[str] = None
    
class SiteTaskIn(BaseModel):
    site_id: str
    title: str
    weight: int = 10

class DailyReportIn(BaseModel):
    site_id: str
    date: str
    notes: str
    completed_tasks: List[str] = []
    issues: List[str] = []
    media_urls: List[dict] = []  # [{url, type: image|video, public_id}]

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

# ---------- AUTH ----------
@api.post("/auth/login", response_model=TokenOut)
async def login(body: LoginIn):
    user = await db.users.find_one({"email": body.email.lower()}, {"_id": 0})
    if not user or not verify_password(body.password, user["password_hash"]):
        raise HTTPException(401, "Invalid credentials")
    if user.get("blocked"):
        raise HTTPException(403, "Account blocked")
    token = create_jwt({"sub": user["id"], "role": user["role"]})
    return {"token": token, "user": serialize_user(user)}

@api.get("/auth/me", response_model=UserOut)
async def me(user: dict = Depends(get_current_user)):
    return serialize_user(user)

@api.post("/auth/register", response_model=ApplicationOut)
async def register_contractor(body: RegisterApplicationIn):
    existing = await db.applications.find_one({"email": body.email.lower(), "status": "PENDING"})
    if existing:
        raise HTTPException(400, "Application already pending for this email")
    if await db.users.find_one({"email": body.email.lower()}):
        raise HTTPException(400, "Email already registered")
    doc = {
        "id": new_id(),
        "company_name": body.company_name,
        "owner_name": body.owner_name,
        "mobile": body.mobile,
        "email": body.email.lower(),
        "gst_number": body.gst_number,
        "office_address": body.office_address,
        "city": body.city,
        "state": body.state,
        "active_projects": body.active_projects,
        "employee_count": body.employee_count,
        "status": "PENDING",
        "created_at": now_iso(),
    }
    await db.applications.insert_one(dict(doc))
    return doc

# ---------- ADMIN ----------
@api.get("/admin/stats")
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

# ---------- SITES ----------
@api.get("/sites")
async def list_sites(user: dict = Depends(get_current_user)):
    q: dict = {}
    if user["role"] == "CONTRACTOR":
        q["company_id"] = user["company_id"]
    elif user["role"] == "SUPERVISOR":
        q["id"] = {"$in": user.get("site_ids", [])}
    elif user["role"] == "CLIENT":
        q["id"] = {"$in": user.get("site_ids", [])}
    else:
        raise HTTPException(403, "Forbidden")
    sites = await db.sites.find(q, {"_id": 0}).sort("created_at", -1).to_list(500)
    return sites

@api.post("/sites")
async def create_site(body: SiteIn, user: dict = Depends(require_roles("CONTRACTOR"))):
    sub = await db.subscriptions.find_one({"company_id": user["company_id"], "status": "ACTIVE"})
    plan = (sub or {}).get("plan", "FREE")
    if plan == "FREE":
        cnt = await db.sites.count_documents({"company_id": user["company_id"]})
        if cnt >= 1:
            raise HTTPException(402, "Free plan allows only 1 site. Upgrade to Premium.")
    site_id = new_id()
    site_data = body.model_dump()
    client = None

    supervisors = []

    for sup_id in body.supervisor_ids:

        sup = await db.users.find_one({
        "id": sup_id,
        "company_id": user["company_id"],
        "role": "SUPERVISOR"
        })

        if sup:
            supervisors.append(sup)

    if body.client_id:
        client = await db.users.find_one({
            "id": body.client_id,
            "company_id": user["company_id"]
        })

    doc = {
        "id": site_id,
        "company_id": user["company_id"],
        "created_by": user["id"],
        "created_at": now_iso(),

        **site_data,

       "supervisor_ids": body.supervisor_ids,

    "supervisor_names": [
        s["full_name"]
            for s in supervisors
        ] if supervisors else None,

         "client_name":
            client.get("full_name") if client else None,

        "client_email":
            client.get("email") if client else None
         }

    await db.sites.insert_one(dict(doc))
    tasks = []

    tasks.extend([
        ("Site Layout", 1),
        ("Excavation", 2),
        ("Mitti Filling", 2)
    ])

    if body.has_boring:
        tasks.append(("Boring", 2))

    if body.has_septic_tank:
        tasks.append(("Septic Tank", 2))

    if body.has_soak_pit:
        tasks.append(("Soak Pit", 2))
        
    tasks.extend([
            ("PCC", 3),
            ("Footing", 4),
            ("Plinth Beam", 4)
    ])

    tasks.extend([
            ("GF Column", 4),
            ("GF Brickwork", 5),
            ("GF Slab", 6)
    ])

    if body.floors >= 2:
        tasks.extend([
            ("FF Column", 4),
            ("FF Brickwork", 5),
            ("FF Slab", 6)
        ])

    if body.floors >= 3:
        tasks.extend([
            ("SF Column", 4),
            ("SF Brickwork", 5),
            ("SF Slab", 6)
        ])

    if body.floors >= 4:
        tasks.extend([
            ("TF Column", 4),
            ("TF Brickwork", 5),
            ("TF Slab", 6)
        ])

    if body.has_mumty:
        tasks.extend([
            ("Mumty Brickwork", 2),
            ("Mumty Slab", 2)
        ])

    tasks.extend([  
            ("Electrical", 3),
            ("Plumbing", 3),
            ("Flooring", 3),
            ("Painting", 3),
            ("Handover", 1)
    ])

    for supervisor in supervisors:

        await db.users.update_one(
            {
                "id": supervisor["id"]
            },
            {
                "$addToSet": {
                    "site_ids": site_id
                }
            }
        )

    if client:
        await db.users.update_one(
            {"id": client["id"]},
            {
                "$addToSet": {
                    "site_ids": site_id
                }
            }
        )
    # Create default site tasks

    for title, weight in tasks:

        await db.site_tasks.insert_one({

            "id": new_id(),

            "site_id": site_id,

            "company_id": user["company_id"],

            "title": title,

            "weight": weight,

            "completed": False,

            "created_at": now_iso()

        })
        
    return doc

@api.get("/sites/{site_id}")
async def get_site(site_id: str, user: dict = Depends(get_current_user)):
    site = await db.sites.find_one({"id": site_id}, {"_id": 0})
    if not site:
        raise HTTPException(404, "Site not found")
    if user["role"] == "CONTRACTOR" and site["company_id"] != user["company_id"]:
        raise HTTPException(403, "Forbidden")
    if user["role"] == "SUPERVISOR" and site_id not in user.get("site_ids", []):
        raise HTTPException(403, "Not assigned")
    if user["role"] == "CLIENT" and site.get("client_email") != user["email"]:
        raise HTTPException(403, "Forbidden")
    return site

@api.put("/sites/{site_id}")
async def update_site(site_id: str, body: SiteIn, user: dict = Depends(require_roles("CONTRACTOR"))):
    res = await db.sites.update_one({"id": site_id, "company_id": user["company_id"]}, {"$set": body.model_dump()})
    if res.matched_count == 0:
        raise HTTPException(404, "Site not found")
    return await db.sites.find_one({"id": site_id}, {"_id": 0})

@api.delete("/sites/{site_id}")
async def delete_site(site_id: str, user: dict = Depends(require_roles("CONTRACTOR"))):
    await db.sites.delete_one({"id": site_id, "company_id": user["company_id"]})
    return {"ok": True}

@api.post("/sites/{site_id}/assign-supervisor")
async def assign_supervisor(
    site_id: str,
    body: SiteAssignmentIn,
    user: dict = Depends(require_roles("CONTRACTOR"))
):

    site = await db.sites.find_one({
        "id": site_id,
        "company_id": user["company_id"]
    })

    if not site:
        raise HTTPException(404, "Site not found")

    supervisor = await db.users.find_one({
        "id": body.user_id,
        "company_id": user["company_id"],
        "role": "SUPERVISOR"
    })

    if not supervisor:
        raise HTTPException(404, "Supervisor not found")

    await db.sites.update_one(
    {"id": site_id},
     {
        "$addToSet": {
            "supervisor_ids": body.user_id
            },          
        }   
    )
    
    updated_site = await db.sites.find_one(
    {"id": site_id}
    )

    names = []
    for sid in updated_site.get(
        "supervisor_ids",
        []
    ):

        sup = await db.users.find_one(
            {"id": sid}
        )

        if sup:
            names.append(
                sup["full_name"]
            )

    await db.sites.update_one(
        {"id": site_id},
        {
            "$set": {
                "supervisor_names": names
            }
        }
    )
    

    await db.users.update_one(
        {"id": body.user_id},
    {
            "$addToSet": {
                "site_ids": site_id
            }
    }
    )

    return {"success": True}

@api.post("/sites/{site_id}/assign-client")
async def assign_client(
    site_id: str,
    body: SiteAssignmentIn,
    user: dict = Depends(require_roles("CONTRACTOR"))
):

    site = await db.sites.find_one({
        "id": site_id,
        "company_id": user["company_id"]
    })

    if not site:
        raise HTTPException(404, "Site not found")

    client = await db.users.find_one({
        "id": body.user_id,
        "company_id": user["company_id"],
        "role": "CLIENT"
    })

    if not client:
        raise HTTPException(404, "Client not found")

    await db.sites.update_one(
        {"id": site_id},
        {
            "$addToSet": {
                "client_ids": body.user_id
            },
            "$set": {
                "client_name": client.get("full_name"),
                "client_email": client.get("email")
            }
        }
    )

    await db.users.update_one(
     {"id": body.user_id},
        {
        "$addToSet": {
            "site_ids": site_id
                 }
        }
    )

    return {"success": True}

# ---------- DASHBOARD STATS ----------
@api.get("/dashboard/contractor")
async def contractor_dashboard(user: dict = Depends(require_roles("CONTRACTOR"))):
    company_id = user["company_id"]
    sites = await db.sites.find({"company_id": company_id}, {"_id": 0}).to_list(500)
    active_sites = sum(1 for s in sites if s["status"] == "ACTIVE")
    total_budget = sum(s.get("budget", 0) for s in sites)
    payments = await db.payments.find({"company_id": company_id}, {"_id": 0}).to_list(2000)
    total_received = sum(p["amount"] for p in payments if p["type"] == "CLIENT_RECEIVED")
    material_cost = sum(p["amount"] for p in payments if p["type"] == "MATERIAL")
    labour_cost = sum(p["amount"] for p in payments if p["type"] == "LABOUR")
    expenses = sum(p["amount"] for p in payments if p["type"] == "EXPENSE")
    pending = max(total_budget - total_received, 0)
    # Site progress chart
    progress = [{"name": s["name"][:12], "progress": s.get("progress", 0)} for s in sites[:8]]
    # Expense breakdown
    breakdown = [
        {"name": "Material", "value": material_cost},
        {"name": "Labour", "value": labour_cost},
        {"name": "Other", "value": expenses},
    ]
    # Recent activity
    activities = await db.notifications.find({"company_id": company_id}, {"_id": 0}).sort("created_at", -1).limit(8).to_list(8)
    return {
        "active_sites": active_sites,
        "total_sites": len(sites),
        "total_budget": total_budget,
        "total_received": total_received,
        "pending_payments": pending,
        "material_cost": material_cost,
        "labour_cost": labour_cost,
        "expenses": expenses,
        "net_profit": total_received - material_cost - labour_cost - expenses,
        "site_progress": progress,
        "expense_breakdown": breakdown,
        "recent_activities": activities,
    }

# ---------- LABOUR ----------
@api.get("/labour")
async def list_labour(site_id: Optional[str] = None, user: dict = Depends(get_current_user)):
    q: dict = {}
    if user["role"] == "CONTRACTOR":
        q["company_id"] = user["company_id"]
    elif user["role"] == "SUPERVISOR":
        q["site_id"] = {"$in": user.get("site_ids", [])}
    else:
        raise HTTPException(403, "Forbidden")
    if site_id:
        q["site_id"] = site_id
    items = await db.labour.find(q, {"_id": 0}).sort("created_at", -1).to_list(1000)
    return items

@api.post("/labour")
async def create_labour(body: LabourIn, user: dict = Depends(require_roles("CONTRACTOR", "SUPERVISOR"))):
    doc = {
        "id": new_id(),
        "company_id": user["company_id"],
        "created_at": now_iso(),
        **body.model_dump(),
    }
    await db.labour.insert_one(dict(doc))
    return doc

@api.delete("/labour/{labour_id}")
async def delete_labour(labour_id: str, user: dict = Depends(require_roles("CONTRACTOR"))):
    await db.labour.delete_one({"id": labour_id, "company_id": user["company_id"]})
    return {"ok": True}

@api.post("/attendance")
async def mark_attendance(body: AttendanceIn, user: dict = Depends(require_roles("CONTRACTOR", "SUPERVISOR"))):
    # Normalize entries: status takes precedence; fallback legacy `present` bool
    norm_entries = []
    for e in body.entries:
        status = e.get("status")
        if not status:
            status = "PRESENT" if e.get("present") else "ABSENT"
        norm_entries.append({
            "labour_id": e["labour_id"],
            "status": status,
            "overtime_hours": float(e.get("overtime_hours") or 0),
            "advance": float(e.get("advance") or 0),
        })

    doc = {
        "id": new_id(),
        "company_id": user["company_id"],
        "site_id": body.site_id,
        "date": body.date,
        "entries": norm_entries,
        "marked_by": user["id"],
        "created_at": now_iso(),
    }
    await db.attendance.update_one(
        {"site_id": body.site_id, "date": body.date},
        {"$set": doc},
        upsert=True,
    )

    # ---- Auto earnings → labour_ledger ----
    from v2 import ATTENDANCE_RATE, recompute_wallet, log_audit

    # 1) Wipe previous ledger entries for this date+site so re-saving is idempotent
    await db.labour_ledger.delete_many({
        "ref_type": "ATTENDANCE",
        "ref_date": body.date,
        "site_id": body.site_id,
    })

    # 2) Build new ledger entries
    labour_ids = [e["labour_id"] for e in norm_entries]
    labour_cursor = db.labour.find({"id": {"$in": labour_ids}})
    labour_docs = {l["id"]: l async for l in labour_cursor}
    touched = set()
    for e in norm_entries:
        labour = labour_docs.get(e["labour_id"])
        if not labour:
            continue
        wage = labour.get("daily_wage", 0)
        factor = ATTENDANCE_RATE.get(e["status"], 0)
        wage_earned = round(wage * factor, 2)
        ot_amount = round((wage / 8) * float(e["overtime_hours"] or 0), 2) if e["overtime_hours"] else 0
        total_earn = wage_earned + ot_amount
        if total_earn > 0:
            await db.labour_ledger.insert_one({
                "id": new_id(),
                "company_id": user["company_id"],
                "labour_id": e["labour_id"],
                "site_id": body.site_id,
                "type": "EARNING",
                "amount": total_earn,
                "note": f"{e['status']} wage{(' + OT ' + str(e['overtime_hours']) + 'h') if ot_amount else ''}",
                "date": body.date,
                "ref_type": "ATTENDANCE",
                "ref_id": doc["id"],
                "ref_date": body.date,
                "created_at": now_iso(),
            })
            touched.add(e["labour_id"])
        if e["advance"] and e["advance"] > 0:
            await db.labour_ledger.insert_one({
                "id": new_id(),
                "company_id": user["company_id"],
                "labour_id": e["labour_id"],
                "site_id": body.site_id,
                "type": "ADVANCE",
                "amount": float(e["advance"]),
                "note": "Daily advance",
                "date": body.date,
                "ref_type": "ATTENDANCE",
                "ref_id": doc["id"],
                "ref_date": body.date,
                "created_at": now_iso(),
            })
            touched.add(e["labour_id"])

    # 3) Recompute wallets for affected labour
    for lid in touched:
        await recompute_wallet(lid)

    await log_audit(user, "UPDATE", "attendance", doc["id"], {"site_id": body.site_id, "date": body.date, "count": len(norm_entries)})
    return doc

@api.get("/attendance")
async def get_attendance(site_id: str, date: Optional[str] = None, user: dict = Depends(get_current_user)):
    q = {"site_id": site_id}
    if date:
        q["date"] = date
        rec = await db.attendance.find_one(q, {"_id": 0})
        return rec or {"site_id": site_id, "date": date, "entries": []}
    recs = await db.attendance.find(q, {"_id": 0}).sort("date", -1).limit(60).to_list(60)
    return recs

# ---------- MATERIALS ----------
@api.get("/materials")
async def list_materials(site_id: Optional[str] = None, user: dict = Depends(get_current_user)):
    q: dict = {}
    if user["role"] == "CONTRACTOR":
        q["company_id"] = user["company_id"]
    elif user["role"] == "SUPERVISOR":
        q["site_id"] = {"$in": user.get("site_ids", [])}
    else:
        raise HTTPException(403, "Forbidden")
    if site_id:
        q["site_id"] = site_id
    return await db.materials.find(q, {"_id": 0}).sort("created_at", -1).to_list(1000)

@api.post("/materials")
async def create_material(body: MaterialIn, user: dict = Depends(require_roles("CONTRACTOR", "SUPERVISOR"))):
    doc = {
        "id": new_id(),
        "company_id": user["company_id"],
        "created_at": now_iso(),
        **body.model_dump(),
    }
    await db.materials.insert_one(dict(doc))
    return doc

@api.post("/material-txns")
async def create_material_txn(body: MaterialTxnIn, user: dict = Depends(require_roles("CONTRACTOR", "SUPERVISOR"))):
    material = await db.materials.find_one({"id": body.material_id}, {"_id": 0})
    if not material:
        raise HTTPException(404, "Material not found")
    delta = body.quantity if body.type == "INWARD" else -body.quantity
    new_stock = material.get("stock", 0) + delta
    await db.materials.update_one({"id": body.material_id}, {"$set": {"stock": new_stock}})
    txn = {
        "id": new_id(),
        "company_id": user["company_id"],
        "created_by": user["id"],
        "created_at": now_iso(),
        **body.model_dump(),
    }
    await db.material_txns.insert_one(dict(txn))
    # Low stock notification
    if new_stock < material.get("low_stock_threshold", 10):
        await db.notifications.insert_one({
            "id": new_id(), "company_id": user["company_id"],
            "title": "Low stock alert", "body": f"{material['name']} is low ({new_stock} {material.get('unit','')})",
            "type": "STOCK", "read": False, "created_at": now_iso(),
        })
    # If inward, log as material payment
    if body.type == "INWARD" and body.rate:
        await db.payments.insert_one({
            "id": new_id(), "company_id": user["company_id"], "site_id": body.site_id,
            "type": "MATERIAL", "amount": body.quantity * body.rate,
            "description": f"{material['name']} from {body.vendor or 'vendor'}",
            "date": now_iso()[:10], "party": body.vendor, "invoice_url": body.invoice_url,
            "created_at": now_iso(),
        })
    return txn

@api.get("/material-txns")
async def list_material_txns(site_id: Optional[str] = None, user: dict = Depends(get_current_user)):
    q: dict = {"company_id": user["company_id"]} if user["role"] != "SUPER_ADMIN" else {}
    if site_id:
        q["site_id"] = site_id
    return await db.material_txns.find(q, {"_id": 0}).sort("created_at", -1).limit(500).to_list(500)

# ---------- PAYMENTS ----------
@api.get("/payments")
async def list_payments(site_id: Optional[str] = None, user: dict = Depends(get_current_user)):
    q: dict = {}
    if user["role"] == "CONTRACTOR":
        q["company_id"] = user["company_id"]
    elif user["role"] == "CLIENT":
        # Client sees payments only for their sites
        sites = await db.sites.find({"client_email": user["email"]}, {"_id": 0, "id": 1}).to_list(100)
        q["site_id"] = {"$in": [s["id"] for s in sites]}
        q["type"] = "CLIENT_RECEIVED"
    elif user["role"] == "SUPERVISOR":
        q["site_id"] = {"$in": user.get("site_ids", [])}
    if site_id:
        q["site_id"] = site_id
    return await db.payments.find(q, {"_id": 0}).sort("date", -1).limit(500).to_list(500)

@api.post("/payments")
async def create_payment(body: PaymentIn, user: dict = Depends(require_roles("CONTRACTOR"))):
    doc = {
        "id": new_id(),
        "company_id": user["company_id"],
        "created_by": user["id"],
        "created_at": now_iso(),
        **body.model_dump(),
    }
    await db.payments.insert_one(dict(doc))
    return doc

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

# ---------- DAILY REPORTS ----------
@api.get("/daily-reports")
async def list_reports(site_id: Optional[str] = None, user: dict = Depends(get_current_user)):
    q: dict = {}
    if user["role"] == "CONTRACTOR":
        q["company_id"] = user["company_id"]
    elif user["role"] == "SUPERVISOR":
        q["site_id"] = {"$in": user.get("site_ids", [])}
    elif user["role"] == "CLIENT":
        sites = await db.sites.find({"client_email": user["email"]}, {"_id": 0, "id": 1}).to_list(100)
        q["site_id"] = {"$in": [s["id"] for s in sites]}
    if site_id:
        q["site_id"] = site_id
    return await db.daily_reports.find(q, {"_id": 0}).sort("date", -1).limit(200).to_list(200)

@api.post("/daily-reports")
async def create_report(body: DailyReportIn, user: dict = Depends(require_roles("CONTRACTOR", "SUPERVISOR"))):
    doc = {
        "id": new_id(),
        "company_id": user["company_id"],
        "created_by": user["id"],
        "created_by_name": user.get("full_name"),
        "created_at": now_iso(),
        **body.model_dump(),
    }
    await db.daily_reports.insert_one(dict(doc))
    for task_title in body.completed_tasks:

        await db.site_tasks.update_one(
            {
                "site_id": body.site_id,
                "title": task_title
            },
            {
                "$set": {
                    "completed": True
                }
            }
        )

    await recalculate_site_progress(
        body.site_id
    )
    if body.issues:
        await db.notifications.insert_one({
            "id": new_id(), "company_id": user["company_id"],
            "title": "Site issue reported",
            "body": f"{len(body.issues)} issue(s) reported on site",
            "type": "SITE", "read": False, "created_at": now_iso(),
        })
    return doc

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
    
from fastapi.responses import FileResponse
@api.get(
    "/maps/files/{filename}"
)
async def map_file(
    filename: str
):

    return FileResponse(
        f"uploads/maps/{filename}"
    )

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

@api.post("/maps/generate")
async def generate_map(
    body: MapRequestIn,
    user: dict = Depends(
        require_roles("CONTRACTOR")
    )
):

    sub = await db.subscriptions.find_one(
        {
            "company_id":
            user["company_id"]
        }
    )

    plan = (
        sub or {}
    ).get(
        "plan",
        "FREE"
    )

    if plan == "FREE":

        raise HTTPException(
            403,
            "Upgrade required"
        )

    if (
        body.type == "3D"
        and plan != "ENTERPRISE"
    ):
        raise HTTPException(
            403,
            "3D available only in Pro Plus"
        )

    site = await db.sites.find_one(
        {
            "id":
            body.site_id
        }
    )

    if not site:

        raise HTTPException(
            404,
            "Site not found"
        )

    doc = {
        "id": new_id(),

        "company_id":
        user["company_id"],

        "site_id":
        body.site_id,

        "project_name":
        site.get("name"),

        "client_name":
        site.get("client_name"),

        **body.model_dump(),

        "status":
        "PENDING",

        "created_at":
        now_iso()
    }

    await db.map_requests.insert_one(
        doc
    )

    branding = await db.companies.find_one(
        {
            "id": user.get("company_id")
        }
    ) or {}

    svg_data = {
        **body.model_dump(),

        "company_name":
        branding.get(
            "name",
            "SiteSeva Pro"
        ),

        "client_name":
        site.get(
            "client_name",
            ""
        ),

        "project_name":
        site.get(
            "name",
            ""
        )
    }
    
    plan = generate_plan(
    body.model_dump()
    )

    await db.floor_plans.insert_one(
        {
            "id": doc["id"],
            "company_id": user["company_id"],
            "site_id": body.site_id,
            "project_name": site.get("name"),
            **plan,
            "created_at": now_iso()
        }
    )

    svg = generate_floor_svg(
        svg_data
    )
    
    print("SITE =", site)
    print("BRANDING =", branding)
    print("SVG DATA =", svg_data)

    file_name = f"{doc['id']}.svg"

    file_path = f"uploads/maps/{file_name}"
    
    os.makedirs(
    "uploads/maps",
    exist_ok=True
    )

    with open(file_path, "w") as f:
        f.write(svg)

    BACKEND_URL = os.getenv(
        "APP_URL",
        "https://sitesevapro-production.up.railway.app"
    )

    image_url = (
        f"{BACKEND_URL}/api/maps/files/{file_name}"
    )

    await db.map_requests.update_one(
        {"id": doc["id"]},
        {
            "$set": {
                "image_url": image_url,
                "status": "COMPLETED"
            }
        }
    )

    doc["image_url"] = image_url
    doc["status"] = "COMPLETED"

    doc.pop("_id", None)

    return {
        "id": doc["id"],
        "image_url": doc["image_url"],
        "status": doc["status"],
        "project_name": doc["project_name"]
    }
    
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

# ---------- NOTIFICATIONS ----------
@api.get("/notifications")
async def list_notifications(user: dict = Depends(get_current_user)):
    q: dict = {}
    if user["role"] == "CONTRACTOR":
        q["company_id"] = user["company_id"]
    elif user["role"] == "SUPERVISOR" or user["role"] == "CLIENT":
        q["$or"] = [{"user_id": user["id"]}, {"company_id": user["company_id"]}]
    return await db.notifications.find(q, {"_id": 0}).sort("created_at", -1).limit(100).to_list(100)

@api.post("/notifications/{notif_id}/read")
async def mark_read(notif_id: str, user: dict = Depends(get_current_user)):
    await db.notifications.update_one({"id": notif_id}, {"$set": {"read": True}})
    return {"ok": True}

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

@app.on_event("startup")
async def on_start():
    try:
        await seed()
    except Exception:
        logger.exception("Seed failed")

@app.on_event("shutdown")
async def on_stop():
    mongo_client.close()
