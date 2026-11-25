"""Site Seva Pro — V2 Phase A endpoints (Labour Wallet, Expenses, Vendors, Estimator, BOQ, Audit, QR payments).

Importable as: `from v2 import v2_router, log_audit, recompute_wallet, ATTENDANCE_RATE`

Depends only on `core` — never on `server` — so the import graph is acyclic.
"""
from __future__ import annotations

import os
from datetime import datetime, timezone, timedelta
from typing import List, Literal, Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel, Field

from core import db, get_current_user, require_roles, new_id, now_iso
from services.design_wallet_service import design_wallet_service
from services.plan_catalog import PLAN_CATALOG, canonical_plan, plan_details
from services.access_control import require_site_access
from services.outbound_notification_service import outbound_notification_service

v2_router = APIRouter(prefix="/api")

# ---------- Audit ----------
async def log_audit(user: dict, action: str, entity: str, entity_id: str, meta: Optional[dict] = None):
    await db.audit_logs.insert_one({
        "id": new_id(),
        "user_id": user["id"],
        "user_email": user.get("email"),
        "user_role": user.get("role"),
        "company_id": user.get("company_id"),
        "action": action,  # CREATE/UPDATE/DELETE/APPROVE/PAY/...
        "entity": entity,  # site/labour/material/payment/...
        "entity_id": entity_id,
        "meta": meta or {},
        "ts": now_iso(),
    })

# ---------- LABOUR WALLET ----------
ATTENDANCE_RATE = {
    "PRESENT": 1.0,
    "HALF": 0.5,
    "HALF_DAY": 0.5,
    "ABSENT": 0.0,
    "LEAVE": 0.0,
}

async def recompute_wallet(labour_id: str) -> dict:
    """Recompute wallet snapshot from ledger entries."""
    pipeline = [
        {"$match": {"labour_id": labour_id}},
        {"$group": {
            "_id": None,
            "earned": {"$sum": {"$cond": [{"$eq": ["$type", "EARNING"]}, "$amount", 0]}},
            "advance": {"$sum": {"$cond": [{"$eq": ["$type", "ADVANCE"]}, "$amount", 0]}},
            "paid": {"$sum": {"$cond": [{"$eq": ["$type", "PAYMENT"]}, "$amount", 0]}},
            "bonus": {"$sum": {"$cond": [{"$eq": ["$type", "BONUS"]}, "$amount", 0]}},
            "deduction": {"$sum": {"$cond": [{"$eq": ["$type", "DEDUCTION"]}, "$amount", 0]}},
        }}
    ]
    res = await db.labour_ledger.aggregate(pipeline).to_list(1)
    totals = res[0] if res else {}
    earned = float(totals.get("earned", 0))
    advance = float(totals.get("advance", 0))
    paid = float(totals.get("paid", 0))
    bonus = float(totals.get("bonus", 0))
    deduction = float(totals.get("deduction", 0))
    total_earned = earned + bonus
    total_paid = advance + paid + deduction
    labour = await db.labour.find_one({"id": labour_id}, {"_id": 0}) or {}
    company_id = labour.get("company_id")
    snap = {
        "id": (await db.labour_wallet.find_one({"labour_id": labour_id}, {"_id": 0, "id": 1}) or {}).get("id", new_id()),
        "company_id": company_id,
        "labour_id": labour_id,
        "site_id": labour.get("site_id"),
        "earned": earned,
        "advance": advance,
        "paid": paid,
        "bonus": bonus,
        "deduction": deduction,
        "total_earned": total_earned,
        "total_paid": total_paid,
        "balance": total_earned - total_paid,
        "updated_at": now_iso(),
    }
    await db.labour_wallet.update_one({"labour_id": labour_id}, {"$set": snap}, upsert=True)
    return snap

class LabourPaymentIn(BaseModel):
    labour_id: str
    amount: float
    type: Literal["PAYMENT", "ADVANCE", "BONUS"] = "PAYMENT"
    note: Optional[str] = None
    date: Optional[str] = None

@v2_router.get("/wallet/summary")
async def wallet_summary(site_id: Optional[str] = None, user: dict = Depends(require_roles("CONTRACTOR", "SUPERVISOR"))):
    q: dict = {"company_id": user["company_id"]}
    if site_id:
        await require_site_access(site_id, user)
        q["site_id"] = site_id
    elif user["role"] == "SUPERVISOR":
        q["site_id"] = {"$in": user.get("site_ids", [])}
    labour = await db.labour.find(q, {"_id": 0}).to_list(2000)
    ids = [l["id"] for l in labour]
    wallets = await db.labour_wallet.find({"labour_id": {"$in": ids}}, {"_id": 0}).to_list(2000)
    wmap = {w["labour_id"]: w for w in wallets}
    rows = []
    total_earned = total_paid = total_balance = 0
    for l in labour:
        w = wmap.get(l["id"], {"total_earned": 0, "total_paid": 0, "balance": 0})
        rows.append({**l, "wallet": w})
        total_earned += w.get("total_earned", 0)
        total_paid += w.get("total_paid", 0)
        total_balance += w.get("balance", 0)
    return {
        "total_earned": total_earned,
        "total_paid": total_paid,
        "total_balance": total_balance,
        "rows": rows,
    }

@v2_router.get("/wallet/labour/{labour_id}")
async def wallet_detail(labour_id: str, user: dict = Depends(require_roles("CONTRACTOR", "SUPERVISOR"))):
    labour = await db.labour.find_one({"id": labour_id, "company_id": user["company_id"]}, {"_id": 0})
    if not labour:
        raise HTTPException(404, "Labour not found")
    wallet = await db.labour_wallet.find_one({"labour_id": labour_id}, {"_id": 0}) or {"total_earned": 0, "total_paid": 0, "balance": 0}
    ledger = await db.labour_ledger.find({"labour_id": labour_id}, {"_id": 0}).sort("date", -1).limit(500).to_list(500)
    return {"labour": labour, "wallet": wallet, "ledger": ledger}

@v2_router.post("/wallet/pay")
async def wallet_pay(body: LabourPaymentIn, user: dict = Depends(require_roles("CONTRACTOR"))):
    labour = await db.labour.find_one({"id": body.labour_id, "company_id": user["company_id"]}, {"_id": 0})
    if not labour:
        raise HTTPException(404, "Labour not found")
    if body.amount <= 0:
        raise HTTPException(400, "Amount must be positive")
    entry = {
        "id": new_id(),
        "company_id": user["company_id"],
        "labour_id": body.labour_id,
        "site_id": labour["site_id"],
        "type": body.type,
        "amount": body.amount,
        "note": body.note,
        "date": body.date or now_iso()[:10],
        "created_by": user["id"],
        "created_at": now_iso(),
    }
    await db.labour_ledger.insert_one(dict(entry))
    snap = await recompute_wallet(body.labour_id)
    # log audit
    await log_audit(user, "PAY", "labour", body.labour_id, {"amount": body.amount, "type": body.type})
    # also log into payments collection as LABOUR
    if body.type in ("PAYMENT", "ADVANCE"):
        await db.payments.insert_one({
            "id": new_id(), "company_id": user["company_id"], "site_id": labour["site_id"],
            "type": "LABOUR", "amount": body.amount,
            "description": f"{body.type.title()} to {labour.get('full_name') or labour.get('name') or 'Labour'}",
            "date": entry["date"], "party": labour.get("full_name") or labour.get("name"), "created_at": now_iso(),
        })
    return {"entry": entry, "wallet": snap}

# ---------- EXPENSES (split module) ----------
class ExpenseIn(BaseModel):
    site_id: str
    category: Literal["FUEL", "TRANSPORT", "EQUIPMENT", "FOOD", "MISC"]
    amount: float
    description: str
    date: str
    paid_by: Optional[str] = None
    receipt_url: Optional[str] = None

@v2_router.get("/expenses")
async def list_expenses(site_id: Optional[str] = None, period: Optional[str] = None, user: dict = Depends(require_roles("CONTRACTOR", "SUPERVISOR"))):
    q: dict = {"company_id": user["company_id"]}
    if user["role"] == "SUPERVISOR":
        q["site_id"] = {"$in": user.get("site_ids", [])}
    if site_id:
        await require_site_access(site_id, user)
        q["site_id"] = site_id
    if period == "month":
        first = datetime.now(timezone.utc).replace(day=1).strftime("%Y-%m-%d")
        q["date"] = {"$gte": first}
    elif period == "today":
        q["date"] = now_iso()[:10]
    items = await db.expenses.find(q, {"_id": 0}).sort("date", -1).limit(1000).to_list(1000)
    return items

@v2_router.post("/expenses")
async def create_expense(body: ExpenseIn, user: dict = Depends(require_roles("CONTRACTOR", "SUPERVISOR"))):
    await require_site_access(body.site_id, user, write=True)
    doc = {
        "id": new_id(),
        "company_id": user["company_id"],
        "created_by": user["id"],
        "created_by_name": user.get("full_name"),
        "created_at": now_iso(),
        **body.model_dump(),
    }
    await db.expenses.insert_one(dict(doc))
    await log_audit(user, "CREATE", "expense", doc["id"], {"amount": body.amount, "category": body.category})
    # mirror into payments for backward-compatible dashboard stats
    await db.payments.insert_one({
        "id": new_id(), "company_id": user["company_id"], "site_id": body.site_id,
        "type": "EXPENSE", "amount": body.amount, "description": f"[{body.category}] {body.description}",
        "date": body.date, "party": body.paid_by, "created_at": now_iso(),
    })
    return doc

@v2_router.get("/expenses/report")
async def expense_report(site_id: Optional[str] = None, user: dict = Depends(require_roles("CONTRACTOR"))):
    q: dict = {"company_id": user["company_id"]}
    if site_id:
        await require_site_access(site_id, user)
        q["site_id"] = site_id
    pipeline = [
        {"$match": q},
        {"$group": {"_id": "$category", "total": {"$sum": "$amount"}, "count": {"$sum": 1}}},
    ]
    by_cat = await db.expenses.aggregate(pipeline).to_list(20)
    monthly = await db.expenses.aggregate([
        {"$match": q},
        {"$group": {"_id": {"$substr": ["$date", 0, 7]}, "total": {"$sum": "$amount"}}},
        {"$sort": {"_id": 1}},
    ]).to_list(24)
    return {"by_category": by_cat, "monthly": monthly}

# ---------- VENDORS ----------
class VendorIn(BaseModel):
    name: str
    contact: Optional[str] = None
    gst: Optional[str] = None
    address: Optional[str] = None
    payment_terms: Optional[str] = None
    categories: List[str] = []

@v2_router.get("/vendors")
async def list_vendors(user: dict = Depends(require_roles("CONTRACTOR"))):
    return await db.vendors.find({"company_id": user["company_id"]}, {"_id": 0}).sort("name", 1).to_list(500)

@v2_router.post("/vendors")
async def create_vendor(body: VendorIn, user: dict = Depends(require_roles("CONTRACTOR"))):
    doc = {"id": new_id(), "company_id": user["company_id"], "created_at": now_iso(), **body.model_dump()}
    await db.vendors.insert_one(dict(doc))
    await log_audit(user, "CREATE", "vendor", doc["id"], {"name": body.name})
    return doc

@v2_router.delete("/vendors/{vendor_id}")
async def delete_vendor(vendor_id: str, user: dict = Depends(require_roles("CONTRACTOR"))):
    await db.vendors.delete_one({"id": vendor_id, "company_id": user["company_id"]})
    await log_audit(user, "DELETE", "vendor", vendor_id)
    return {"ok": True}

# ---------- ESTIMATION ENGINE ----------
class EstimateIn(BaseModel):
    site_id: Optional[str] = None
    name: str
    plot_area_sqft: float
    floors: int = 1
    basement: bool = False
    construction_type: Literal["RESIDENTIAL", "COMMERCIAL", "SEMI_COMMERCIAL", "INDUSTRIAL"] = "RESIDENTIAL"
    quality: Literal["ECONOMY", "BASIC", "STANDARD", "PREMIUM", "LUXURY"] = "STANDARD"
    budget: float  # total budget in INR

TYPE_FACTOR = {"RESIDENTIAL": 1.0, "SEMI_COMMERCIAL": 1.08, "COMMERCIAL": 1.15, "INDUSTRIAL": 1.25}

# Cost-mix shifts with quality tier: premium projects carry richer finishes (material↑)
# while economy builds tilt to labour. Tuned from typical Indian-residential ratios.
QUALITY_MIX = {
    "ECONOMY":  {"material": 0.48, "labour": 0.36, "overhead": 0.16},
    "BASIC":    {"material": 0.52, "labour": 0.33, "overhead": 0.15},
    "STANDARD": {"material": 0.55, "labour": 0.30, "overhead": 0.15},
    "PREMIUM":  {"material": 0.60, "labour": 0.26, "overhead": 0.14},
    "LUXURY":   {"material": 0.65, "labour": 0.22, "overhead": 0.13},
}

@v2_router.post("/estimates")
async def create_estimate(body: EstimateIn, user: dict = Depends(require_roles("CONTRACTOR"))):
    if body.budget <= 0:
        raise HTTPException(400, "Budget must be greater than 0")
    if body.plot_area_sqft <= 0 or body.floors <= 0:
        raise HTTPException(400, "Plot area and floors must be > 0")
    if body.site_id:
        await require_site_access(body.site_id, user, write=True)

    # Basement counts as ~0.85 floor (excavation + waterproofing offset reduces effective rate slightly)
    effective_floors = body.floors + (0.85 if body.basement else 0)
    builtup = body.plot_area_sqft * effective_floors

    # Material formulas scale with built-up; basements need extra steel/cement for waterproofing
    base_cement = 0.4
    base_steel = 4.0
    if body.basement:
        base_cement *= 1.06
        base_steel *= 1.10

    cement_bags = round(builtup * base_cement, 2)
    steel_kg = round(builtup * base_steel, 2)
    sand_cft = round(builtup * 0.85, 2)
    aggregate_cft = round(builtup * 0.65, 2)
    bricks_pcs = round(builtup * 8.0, 2)

    rate_psf = body.budget / builtup
    mix = QUALITY_MIX[body.quality]
    total = round(body.budget, 2)
    material_cost = round(total * mix["material"], 2)
    labour_cost = round(total * mix["labour"], 2)
    overhead = round(total - material_cost - labour_cost, 2)

    doc = {
        "id": new_id(),
        "company_id": user["company_id"],
        "site_id": body.site_id,
        "name": body.name,
        "input": body.model_dump(),
        "builtup_sqft": round(builtup, 2),
        "rate_per_sqft": round(rate_psf, 2),
        "quality_band": body.quality,
        "type_factor": TYPE_FACTOR[body.construction_type],
        "materials": {
            "cement_bags": cement_bags,
            "steel_kg": steel_kg,
            "sand_cft": sand_cft,
            "aggregate_cft": aggregate_cft,
            "bricks_pcs": bricks_pcs,
        },
        "material_cost": material_cost,
        "labour_cost": labour_cost,
        "overhead": overhead,
        "total": total,
        "created_by": user["id"],
        "created_at": now_iso(),
    }
    await db.estimates.insert_one(dict(doc))
    await log_audit(user, "CREATE", "estimate", doc["id"], {"total": total, "rate_per_sqft": rate_psf, "quality": body.quality})
    return doc

@v2_router.get("/estimates")
async def list_estimates(user: dict = Depends(require_roles("CONTRACTOR"))):
    return await db.estimates.find({"company_id": user["company_id"]}, {"_id": 0}).sort("created_at", -1).to_list(200)

@v2_router.get("/estimates/{est_id}")
async def get_estimate(est_id: str, user: dict = Depends(require_roles("CONTRACTOR", "CLIENT"))):
    q = {"id": est_id, "company_id": user["company_id"]}
    e = await db.estimates.find_one(q, {"_id": 0})
    if not e:
        raise HTTPException(404, "Not found")
    if user["role"] == "CLIENT":
        if not e.get("site_id"):
            raise HTTPException(403, "This estimate is not assigned to a client site")
        await require_site_access(e["site_id"], user)
    return e

# ---------- BOQ ----------
class BOQGenerateIn(BaseModel):
    estimate_id: Optional[str] = None
    site_id: Optional[str] = None
    name: str
    builtup_sqft: Optional[float] = None

BOQ_TEMPLATE = [
    ("Foundation", [
        ("PCC bed", "cum", 0.05, 6500),
        ("RCC footing", "cum", 0.06, 8500),
        ("Earthwork excavation", "cum", 0.12, 320),
    ]),
    ("RCC Work", [
        ("Columns & beams", "cum", 0.09, 9200),
        ("Slabs", "cum", 0.12, 8800),
    ]),
    ("Brickwork", [
        ("9\" external walls", "cum", 0.18, 6200),
        ("4.5\" internal walls", "cum", 0.10, 5800),
    ]),
    ("Plaster", [
        ("Internal plaster", "sqm", 2.5, 240),
        ("External plaster", "sqm", 1.2, 280),
    ]),
    ("Flooring", [
        ("Vitrified tiles", "sqm", 0.9, 1450),
        ("Bathroom tiles", "sqm", 0.2, 1100),
    ]),
    ("Painting", [
        ("Internal emulsion", "sqm", 3.0, 95),
        ("External weatherproof", "sqm", 1.4, 140),
    ]),
    ("Electrical", [("Wiring & fixtures", "sqft", 1.0, 145)]),
    ("Plumbing", [("Piping & fixtures", "sqft", 1.0, 95)]),
]

@v2_router.post("/boq/generate")
async def generate_boq(body: BOQGenerateIn, user: dict = Depends(require_roles("CONTRACTOR"))):
    builtup = body.builtup_sqft
    if body.estimate_id:
        est = await db.estimates.find_one({"id": body.estimate_id, "company_id": user["company_id"]}, {"_id": 0})
        if not est:
            raise HTTPException(404, "Estimate not found")
        builtup = est["builtup_sqft"]
    if not builtup or builtup <= 0:
        raise HTTPException(400, "builtup_sqft or estimate_id required")
    if body.site_id:
        await require_site_access(body.site_id, user, write=True)
    sqm = builtup / 10.764
    sections = []
    grand = 0
    for sec_name, items in BOQ_TEMPLATE:
        rows = []
        sub = 0
        for desc, unit, factor, rate in items:
            base = sqm if unit == "sqm" else (builtup if unit == "sqft" else builtup * 0.0929)
            qty = round(base * factor, 2)
            amt = round(qty * rate, 2)
            sub += amt
            rows.append({"desc": desc, "unit": unit, "qty": qty, "rate": rate, "amount": amt})
        grand += sub
        sections.append({"name": sec_name, "items": rows, "subtotal": round(sub, 2)})
    doc = {
        "id": new_id(),
        "company_id": user["company_id"],
        "estimate_id": body.estimate_id,
        "site_id": body.site_id,
        "name": body.name,
        "builtup_sqft": builtup,
        "sections": sections,
        "total": round(grand, 2),
        "created_by": user["id"],
        "created_at": now_iso(),
    }
    await db.boqs.insert_one(dict(doc))
    await log_audit(user, "CREATE", "boq", doc["id"], {"total": grand})
    return doc

@v2_router.get("/boq")
async def list_boqs(user: dict = Depends(require_roles("CONTRACTOR"))):
    return await db.boqs.find({"company_id": user["company_id"]}, {"_id": 0}).sort("created_at", -1).to_list(200)

@v2_router.get("/boq/{boq_id}")
async def get_boq(boq_id: str, user: dict = Depends(require_roles("CONTRACTOR", "CLIENT"))):
    q = {"id": boq_id, "company_id": user["company_id"]}
    b = await db.boqs.find_one(q, {"_id": 0})
    if not b:
        raise HTTPException(404, "Not found")
    if user["role"] == "CLIENT":
        if not b.get("site_id"):
            raise HTTPException(403, "This BOQ is not assigned to a client site")
        await require_site_access(b["site_id"], user)
    return b

# ---------- QR PAYMENT FLOW (UPI) ----------
PLAN_PRICES = {code: details["price"] for code, details in PLAN_CATALOG.items()}

class PaymentRequestIn(BaseModel):
    plan: Literal["PREMIUM", "ENTERPRISE"]
    utr: str = Field(..., min_length=4, max_length=40)
    screenshot_url: Optional[str] = None
    note: Optional[str] = None

@v2_router.get("/payment/config")
async def payment_config(user: dict = Depends(get_current_user)):
    upi_id = os.environ.get("UPI_ID", "").strip()
    payee_name = os.environ.get("UPI_PAYEE_NAME", "").strip()
    if not upi_id or not payee_name:
        raise HTTPException(503, "Payment collection is not configured")
    return {
        "upi_id": upi_id,
        "payee_name": payee_name,
        "prices": PLAN_PRICES,
    }

@v2_router.post("/payment/request")
async def create_payment_request(body: PaymentRequestIn, user: dict = Depends(require_roles("CONTRACTOR"))):
    if not os.environ.get("UPI_ID", "").strip():
        raise HTTPException(503, "Payment collection is not configured")
    duplicate = await db.payment_requests.find_one({"utr": body.utr, "status": {"$in": ["PENDING", "PROCESSING", "APPROVED"]}}, {"_id": 0, "id": 1})
    if duplicate:
        raise HTTPException(409, "This UTR has already been submitted")
    amount = PLAN_PRICES[body.plan]
    doc = {
        "id": new_id(),
        "company_id": user["company_id"],
        "user_id": user["id"],
        "user_email": user["email"],
        "company_name": user.get("company_name"),
        "plan": body.plan,
        "amount": amount,
        "utr": body.utr,
        "screenshot_url": body.screenshot_url,
        "note": body.note,
        "status": "PENDING",
        "created_at": now_iso(),
    }
    await db.payment_requests.insert_one(dict(doc))
    await log_audit(user, "CREATE", "payment_request", doc["id"], {"plan": body.plan, "amount": amount, "utr": body.utr})
    await db.notifications.insert_one({
        "id": new_id(), "user_id": user["id"], "company_id": user["company_id"],
        "title": "Payment submitted",
        "body": f"Your {body.plan} payment of ₹{amount} is pending admin verification.",
        "type": "SUBSCRIPTION", "read": False, "created_at": now_iso(),
    })
    return doc

@v2_router.get("/payment/my")
async def my_payment_requests(user: dict = Depends(require_roles("CONTRACTOR"))):
    return await db.payment_requests.find({"company_id": user["company_id"]}, {"_id": 0}).sort("created_at", -1).limit(50).to_list(50)

@v2_router.get("/admin/payments")
async def admin_payment_requests(status: Optional[str] = None, _: dict = Depends(require_roles("SUPER_ADMIN"))):
    q = {}
    if status:
        q["status"] = status
    return await db.payment_requests.find(q, {"_id": 0}).sort("created_at", -1).limit(500).to_list(500)

@v2_router.post("/admin/payments/{pid}/approve")
async def approve_payment(pid: str, admin: dict = Depends(require_roles("SUPER_ADMIN"))):
    p = await db.payment_requests.find_one({"id": pid}, {"_id": 0})
    if not p:
        raise HTTPException(404, "Not found")
    if p["status"] != "PENDING":
        raise HTTPException(400, "Already processed")
    claim = await db.payment_requests.update_one(
        {"id": pid, "status": "PENDING"},
        {"$set": {"status": "PROCESSING", "processing_at": now_iso(), "processed_by": admin["id"]}},
    )
    if claim.modified_count == 0:
        raise HTTPException(409, "Payment is already being processed")
    try:
        expires = (datetime.now(timezone.utc) + timedelta(days=30)).isoformat()
        await db.subscriptions.update_one(
            {"company_id": p["company_id"]},
            {"$set": {
                "id": new_id(), "company_id": p["company_id"], "plan": p["plan"], "status": "ACTIVE",
                "started_at": now_iso(), "expires_at": expires, "amount": p["amount"],
            }},
            upsert=True,
        )
        await db.users.update_one({"id": p["user_id"]}, {"$set": {"plan": p["plan"]}})
        credits = plan_details(p["plan"])["monthly_design_credits"]
        await design_wallet_service.balance(p["company_id"])
        await design_wallet_service.add(p["company_id"], credits, f"{p['plan']} subscription credits · UTR {p['utr']}")
        await db.payments.insert_one({
            "id": new_id(), "company_id": p["company_id"], "site_id": None,
            "type": "SUBSCRIPTION", "amount": p["amount"],
            "description": f"{p['plan']} plan via UPI · UTR {p['utr']}",
            "date": now_iso()[:10], "created_at": now_iso(),
        })
        await db.payment_requests.update_one({"id": pid, "status": "PROCESSING"}, {"$set": {
            "status": "APPROVED", "approved_at": now_iso(), "approved_by": admin["id"],
        }})
        await db.notifications.insert_one({
            "id": new_id(), "user_id": p["user_id"], "company_id": p["company_id"],
            "title": "Subscription activated",
            "body": f"Your {p['plan']} plan is now active. Expires {expires[:10]}.",
            "type": "SUBSCRIPTION", "read": False, "created_at": now_iso(),
        })
        await log_audit(admin, "APPROVE", "payment_request", pid, {"plan": p["plan"], "amount": p["amount"]})
        contractor = await db.users.find_one({"id": p["user_id"]}, {"_id": 0}) or {}
        delivery = await outbound_notification_service.send_approval(
            contractor,
            "Subscription payment approved",
            f"Your {p['plan']} plan is active until {expires[:10]}.",
            event="SUBSCRIPTION_PAYMENT_APPROVED",
        )
        return {"ok": True, "whatsapp_delivery": delivery}
    except Exception as error:
        await db.payment_requests.update_one(
            {"id": pid, "status": "PROCESSING"},
            {"$set": {"status": "FAILED", "processing_error": str(error)[:500], "failed_at": now_iso()}},
        )
        raise HTTPException(500, "Payment approval failed and was locked for admin review") from error

@v2_router.post("/admin/payments/{pid}/reject")
async def reject_payment(pid: str, reason: str = Query(""), admin: dict = Depends(require_roles("SUPER_ADMIN"))):
    p = await db.payment_requests.find_one({"id": pid}, {"_id": 0})
    if not p:
        raise HTTPException(404, "Not found")
    if p.get("status") != "PENDING":
        raise HTTPException(409, "Payment has already been processed")
    result = await db.payment_requests.update_one({"id": pid, "status": "PENDING"}, {"$set": {
        "status": "REJECTED", "rejected_at": now_iso(), "rejected_by": admin["id"], "reject_reason": reason,
    }})
    if result.modified_count == 0:
        raise HTTPException(409, "Payment has already been processed")
    await db.notifications.insert_one({
        "id": new_id(), "user_id": p["user_id"], "company_id": p["company_id"],
        "title": "Payment rejected",
        "body": f"Your {p['plan']} payment was rejected. {reason or 'Please contact support.'}",
        "type": "SUBSCRIPTION", "read": False, "created_at": now_iso(),
    })
    await log_audit(admin, "REJECT", "payment_request", pid, {"reason": reason})
    return {"ok": True}

# ---------- AUDIT LOGS (admin) ----------
@v2_router.get("/admin/audit")
async def list_audit(
    entity: Optional[str] = None,
    user_id: Optional[str] = None,
    limit: int = 200,
    _: dict = Depends(require_roles("SUPER_ADMIN")),
):
    q = {}
    if entity:
        q["entity"] = entity
    if user_id:
        q["user_id"] = user_id
    return await db.audit_logs.find(q, {"_id": 0}).sort("ts", -1).limit(min(limit, 1000)).to_list(limit)

# ---------- ADVANCED EXECUTIVE DASHBOARD ----------
@v2_router.get("/dashboard/executive")
async def executive_dashboard(user: dict = Depends(require_roles("CONTRACTOR"))):
    cid = user["company_id"]
    sites = await db.sites.find({"company_id": cid}, {"_id": 0}).to_list(500)
    active_sites = [s for s in sites if s["status"] == "ACTIVE"]
    supervisors = await db.users.count_documents({"company_id": cid, "role": "SUPERVISOR", "blocked": {"$ne": True}})
    labour_total = await db.labour.count_documents({"company_id": cid})
    payments = await db.payments.find({"company_id": cid}, {"_id": 0}).to_list(5000)
    received = sum(p["amount"] for p in payments if p["type"] == "CLIENT_RECEIVED")
    labour_cost = sum(p["amount"] for p in payments if p["type"] == "LABOUR")
    material_cost = sum(p["amount"] for p in payments if p["type"] == "MATERIAL")
    expenses = sum(p["amount"] for p in payments if p["type"] == "EXPENSE")
    total_budget = sum(s.get("budget", 0) for s in sites)
    pending = max(total_budget - received, 0)
    profit = received - labour_cost - material_cost - expenses

    # Site profitability
    site_profit = []
    for s in sites:
        sp = [p for p in payments if p.get("site_id") == s["id"]]
        rec = sum(p["amount"] for p in sp if p["type"] == "CLIENT_RECEIVED")
        cost = sum(p["amount"] for p in sp if p["type"] in ("LABOUR", "MATERIAL", "EXPENSE"))
        site_profit.append({"name": s["name"][:14], "received": rec, "cost": cost, "profit": rec - cost})

    # 6-month trend
    months = {}
    for p in payments:
        key = (p.get("date") or "")[:7]
        if not key:
            continue
        months.setdefault(key, {"month": key, "received": 0, "expense": 0})
        if p["type"] == "CLIENT_RECEIVED":
            months[key]["received"] += p["amount"]
        elif p["type"] in ("LABOUR", "MATERIAL", "EXPENSE"):
            months[key]["expense"] += p["amount"]
    trend = sorted(months.values(), key=lambda x: x["month"])[-6:]

    return {
        "active_sites": len(active_sites),
        "total_sites": len(sites),
        "supervisors": supervisors,
        "total_labour": labour_total,
        "labour_cost": labour_cost,
        "material_cost": material_cost,
        "expenses": expenses,
        "received": received,
        "pending": pending,
        "profit": profit,
        "site_profitability": site_profit[:10],
        "trend": trend,
    }
