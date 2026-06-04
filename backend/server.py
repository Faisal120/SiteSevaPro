"""Site Seva Pro - FastAPI backend (single-file)."""
from __future__ import annotations

import asyncio
import logging
import os
import secrets
import time
import uuid
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Annotated, Any, List, Literal, Optional

import bcrypt
import cloudinary
import cloudinary.utils
import jwt
from dotenv import load_dotenv
from fastapi import APIRouter, Depends, FastAPI, HTTPException, Query, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from motor.motor_asyncio import AsyncIOMotorClient
from pydantic import BaseModel, EmailStr, Field
from starlette.middleware.cors import CORSMiddleware

ROOT_DIR = Path(__file__).parent
load_dotenv(ROOT_DIR / ".env")

# -------- Config --------
MONGO_URL = os.environ["MONGO_URL"]
DB_NAME = os.environ["DB_NAME"]
JWT_SECRET = os.environ["JWT_SECRET"]
JWT_ALGORITHM = os.environ.get("JWT_ALGORITHM", "HS256")
JWT_EXPIRE_HOURS = int(os.environ.get("JWT_EXPIRE_HOURS", "720"))
SUPER_ADMIN_EMAIL = os.environ["SUPER_ADMIN_EMAIL"]
SUPER_ADMIN_PASSWORD = os.environ["SUPER_ADMIN_PASSWORD"]

cloudinary.config(
    cloud_name=os.environ["CLOUDINARY_CLOUD_NAME"],
    api_key=os.environ["CLOUDINARY_API_KEY"],
    api_secret=os.environ["CLOUDINARY_API_SECRET"],
    secure=True,
)

EMERGENT_LLM_KEY = os.environ.get("EMERGENT_LLM_KEY")

logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(name)s - %(levelname)s - %(message)s")
logger = logging.getLogger("siteseva")

# -------- Mongo --------
client = AsyncIOMotorClient(MONGO_URL)
db = client[DB_NAME]

# -------- Helpers --------
def now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()

def new_id() -> str:
    return str(uuid.uuid4())

def hash_password(pw: str) -> str:
    return bcrypt.hashpw(pw.encode(), bcrypt.gensalt()).decode()

def verify_password(pw: str, hashed: str) -> bool:
    try:
        return bcrypt.checkpw(pw.encode(), hashed.encode())
    except Exception:
        return False

def create_jwt(payload: dict) -> str:
    data = {**payload, "exp": datetime.now(timezone.utc) + timedelta(hours=JWT_EXPIRE_HOURS), "iat": datetime.now(timezone.utc)}
    return jwt.encode(data, JWT_SECRET, algorithm=JWT_ALGORITHM)

def decode_jwt(token: str) -> dict:
    return jwt.decode(token, JWT_SECRET, algorithms=[JWT_ALGORITHM])

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
    client_name: str
    client_email: Optional[EmailStr] = None
    location: str
    budget: float
    start_date: str
    end_date: str
    status: Literal["PLANNING", "ACTIVE", "ON_HOLD", "COMPLETED"] = "ACTIVE"
    progress: int = 0
    description: Optional[str] = None
    supervisor_ids: List[str] = []
    cover_image: Optional[str] = None

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
    entries: List[dict]  # [{labour_id, present, overtime_hours, advance}]

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

# -------- Auth dependency --------
bearer = HTTPBearer(auto_error=False)

async def get_current_user(creds: Optional[HTTPAuthorizationCredentials] = Depends(bearer)) -> dict:
    if not creds:
        raise HTTPException(401, "Missing token")
    try:
        payload = decode_jwt(creds.credentials)
    except jwt.PyJWTError:
        raise HTTPException(401, "Invalid token")
    user = await db.users.find_one({"id": payload.get("sub")}, {"_id": 0})
    if not user:
        raise HTTPException(401, "User not found")
    if user.get("blocked"):
        raise HTTPException(403, "Account blocked")
    return user

def require_roles(*roles: str):
    async def dep(user: dict = Depends(get_current_user)) -> dict:
        if user["role"] not in roles:
            raise HTTPException(403, f"Requires one of {roles}")
        return user
    return dep

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
    # Revenue trend (last 6 months mocked aggregate)
    months = []
    for i in range(5, -1, -1):
        dt = datetime.now(timezone.utc) - timedelta(days=30 * i)
        label = dt.strftime("%b")
        months.append({"month": label, "revenue": int(50000 + secrets.randbelow(80000))})
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

@api.post("/admin/contractors/{user_id}/block")
async def block_contractor(user_id: str, blocked: bool = True, _: dict = Depends(require_roles("SUPER_ADMIN"))):
    res = await db.users.update_one({"id": user_id}, {"$set": {"blocked": blocked}})
    if res.matched_count == 0:
        raise HTTPException(404, "User not found")
    return {"ok": True, "blocked": blocked}

# ---------- SITES ----------
@api.get("/sites")
async def list_sites(user: dict = Depends(get_current_user)):
    q: dict = {}
    if user["role"] == "CONTRACTOR":
        q["company_id"] = user["company_id"]
    elif user["role"] == "SUPERVISOR":
        q["id"] = {"$in": user.get("site_ids", [])}
    elif user["role"] == "CLIENT":
        q["client_email"] = user["email"]
    elif user["role"] == "SUPER_ADMIN":
        pass
    sites = await db.sites.find(q, {"_id": 0}).sort("created_at", -1).to_list(500)
    return sites

@api.post("/sites")
async def create_site(body: SiteIn, user: dict = Depends(require_roles("CONTRACTOR"))):
    # Plan enforcement
    sub = await db.subscriptions.find_one({"company_id": user["company_id"], "status": "ACTIVE"})
    plan = (sub or {}).get("plan", "FREE")
    if plan == "FREE":
        cnt = await db.sites.count_documents({"company_id": user["company_id"]})
        if cnt >= 1:
            raise HTTPException(402, "Free plan allows only 1 site. Upgrade to Premium.")
    site_id = new_id()
    doc = {
        "id": site_id,
        "company_id": user["company_id"],
        "created_by": user["id"],
        "created_at": now_iso(),
        **body.model_dump(),
    }
    await db.sites.insert_one(dict(doc))
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
    doc = {
        "id": new_id(),
        "company_id": user["company_id"],
        "marked_by": user["id"],
        "created_at": now_iso(),
        **body.model_dump(),
    }
    # Upsert by site + date
    await db.attendance.update_one(
        {"site_id": body.site_id, "date": body.date},
        {"$set": doc},
        upsert=True,
    )
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
    if body.issues:
        await db.notifications.insert_one({
            "id": new_id(), "company_id": user["company_id"],
            "title": "Site issue reported",
            "body": f"{len(body.issues)} issue(s) reported on site",
            "type": "SITE", "read": False, "created_at": now_iso(),
        })
    return doc

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
    amounts = {"FREE": 0, "PREMIUM": 4999, "ENTERPRISE": 14999}
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
    try:
        reply = await chat.send_message(msg)
    except Exception as e:
        logger.exception("AI error")
        raise HTTPException(502, f"AI service error: {e}")
    return {"kind": body.kind, "insight": reply, "generated_at": now_iso()}

# ---------- MOUNT ----------
app.include_router(api)
app.add_middleware(
    CORSMiddleware,
    allow_credentials=True,
    allow_origins=os.environ.get("CORS_ORIGINS", "*").split(","),
    allow_methods=["*"],
    allow_headers=["*"],
)

# ---------- STARTUP SEED ----------
async def seed():
    # Super Admin
    existing = await db.users.find_one({"email": SUPER_ADMIN_EMAIL.lower()})
    if not existing:
        await db.users.insert_one({
            "id": new_id(),
            "email": SUPER_ADMIN_EMAIL.lower(),
            "username": "superadmin",
            "password_hash": hash_password(SUPER_ADMIN_PASSWORD),
            "role": "SUPER_ADMIN",
            "full_name": "Platform Admin",
            "blocked": False,
            "created_at": now_iso(),
        })
        logger.info("Seeded SUPER_ADMIN")
    # Demo Contractor + Company
    contractor = await db.users.find_one({"email": "contractor@demo.com"})
    if not contractor:
        company_id = new_id()
        user_id = new_id()
        await db.companies.insert_one({
            "id": company_id, "name": "Demo Builders Pvt Ltd",
            "owner_id": user_id, "gst_number": "27ABCDE1234F1Z5",
            "city": "Mumbai", "state": "Maharashtra",
            "address": "101, Construction House, BKC", "created_at": now_iso(),
        })
        await db.users.insert_one({
            "id": user_id, "email": "contractor@demo.com", "username": "demobuilders",
            "password_hash": hash_password("Contractor@2026"), "role": "CONTRACTOR",
            "full_name": "Rajesh Sharma", "company_id": company_id,
            "company_name": "Demo Builders Pvt Ltd", "plan": "PREMIUM",
            "site_ids": [], "blocked": False, "created_at": now_iso(),
        })
        await db.subscriptions.insert_one({
            "id": new_id(), "company_id": company_id, "plan": "PREMIUM", "status": "ACTIVE",
            "started_at": now_iso(),
            "expires_at": (datetime.now(timezone.utc) + timedelta(days=30)).isoformat(),
            "amount": 4999,
        })
        # Sample sites
        sites = []
        for i, sd in enumerate([
            ("Skyline Towers Phase 1", "Anil Mehta", "anil@client.com", "Andheri West, Mumbai", 25000000, 65, "ACTIVE"),
            ("Green Valley Residency", "Priya Desai", "client@demo.com", "Pune, Maharashtra", 18000000, 40, "ACTIVE"),
            ("Coastal Business Park", "Vikram Singh", "vikram@client.com", "Goa", 42000000, 15, "PLANNING"),
        ]):
            sid = new_id()
            site = {
                "id": sid, "company_id": company_id, "name": sd[0],
                "client_name": sd[1], "client_email": sd[2], "location": sd[3],
                "budget": sd[4], "progress": sd[5], "status": sd[6],
                "start_date": "2026-01-15", "end_date": "2026-12-30",
                "description": "Premium construction project.", "supervisor_ids": [], "cover_image": None,
                "created_by": user_id, "created_at": now_iso(),
            }
            await db.sites.insert_one(dict(site))
            sites.append(sid)
        # Demo supervisor
        sup_id = new_id()
        await db.users.insert_one({
            "id": sup_id, "email": "supervisor@demo.com", "username": "supervisor1",
            "password_hash": hash_password("Supervisor@2026"), "role": "SUPERVISOR",
            "full_name": "Amit Kumar", "company_id": company_id,
            "company_name": "Demo Builders Pvt Ltd",
            "site_ids": sites[:2], "blocked": False, "created_at": now_iso(),
        })
        # Demo client linked to site #2
        await db.users.insert_one({
            "id": new_id(), "email": "client@demo.com", "username": "client1",
            "password_hash": hash_password("Client@2026"), "role": "CLIENT",
            "full_name": "Priya Desai", "company_id": company_id,
            "company_name": "Demo Builders Pvt Ltd",
            "blocked": False, "created_at": now_iso(),
        })
        # Sample labour
        for nm, rl, w in [("Ramesh", "Mason", 800), ("Suresh", "Helper", 500), ("Mahesh", "Electrician", 1200), ("Kishore", "Plumber", 1000)]:
            await db.labour.insert_one({
                "id": new_id(), "company_id": company_id, "site_id": sites[0],
                "name": nm, "role": rl, "daily_wage": w, "mobile": "9999911111",
                "aadhaar": None, "created_at": now_iso(),
            })
        # Sample materials
        for n, c, u, s, t, r in [
            ("OPC Cement 53", "Cement", "bags", 120, 50, 410),
            ("TMT Steel Rods", "Steel", "kg", 2500, 1000, 72),
            ("River Sand", "Sand", "cft", 80, 100, 65),
            ("Red Bricks", "Bricks", "pcs", 8500, 2000, 9),
            ("Vitrified Tiles", "Tiles", "sqft", 5, 50, 65),
        ]:
            await db.materials.insert_one({
                "id": new_id(), "company_id": company_id, "site_id": sites[0],
                "name": n, "category": c, "unit": u, "stock": s,
                "low_stock_threshold": t, "rate": r, "created_at": now_iso(),
            })
        # Sample payments
        for t, a, d, dt, p in [
            ("CLIENT_RECEIVED", 8000000, "Phase 1 advance from client", "2026-01-20", "Anil Mehta"),
            ("CLIENT_RECEIVED", 4000000, "Phase 2 milestone payment", "2026-02-10", "Anil Mehta"),
            ("MATERIAL", 850000, "Cement & steel purchase", "2026-01-25", "Ultratech"),
            ("LABOUR", 320000, "January labour wages", "2026-01-31", "Site team"),
            ("EXPENSE", 45000, "Diesel for machinery", "2026-02-05", "HP Pump"),
        ]:
            await db.payments.insert_one({
                "id": new_id(), "company_id": company_id, "site_id": sites[0],
                "type": t, "amount": a, "description": d, "date": dt, "party": p,
                "created_at": now_iso(),
            })
        # Sample report
        await db.daily_reports.insert_one({
            "id": new_id(), "company_id": company_id, "site_id": sites[0],
            "date": now_iso()[:10], "notes": "Slab work on 7th floor completed. Curing started.",
            "completed_tasks": ["7th floor slab", "Electrical conduit on 6th floor"],
            "issues": ["Material delivery delayed by 2 hrs"],
            "media_urls": [],
            "created_by": sup_id, "created_by_name": "Amit Kumar",
            "created_at": now_iso(),
        })
        # Sample notifications
        for ttl, bd, tp in [
            ("Payment received", "₹40,00,000 received from Anil Mehta", "PAYMENT"),
            ("Low stock alert", "Vitrified Tiles below threshold", "STOCK"),
            ("Site issue", "Material delivery delayed at Skyline Towers", "SITE"),
        ]:
            await db.notifications.insert_one({
                "id": new_id(), "company_id": company_id,
                "title": ttl, "body": bd, "type": tp, "read": False, "created_at": now_iso(),
            })
        logger.info("Seeded demo contractor + sample data")

@app.on_event("startup")
async def on_start():
    try:
        await seed()
    except Exception:
        logger.exception("Seed failed")

@app.on_event("shutdown")
async def on_stop():
    client.close()
