"""Site Seva Pro — V2 Phase A endpoints (Labour Wallet, Expenses, Vendors, Estimator, BOQ, Audit, QR payments).

Importable as: `from v2 import v2_router, log_audit, recompute_wallet, ATTENDANCE_RATE`
"""
from __future__ import annotations

import os
import uuid
from datetime import datetime, timezone, timedelta
from typing import Any, List, Literal, Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel, Field

# Re-imported from server.py — circular safe because v2 is imported AFTER models/db defined
from server import (
    db, get_current_user, require_roles, new_id, now_iso,
)

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
ATTENDANCE_RATE = {"PRESENT": 1.0, "HALF": 0.5, "ABSENT": 0.0}

async def recompute_wallet(labour_id: str) -> dict:
    """Recompute wallet snapshot from ledger entries."""
    pipeline = [
        {"$match": {"labour_id": labour_id}},
        {"$group": {
            "_id": None,
            "earned": {"$sum": {"$cond": [{"$in": ["$type", ["EARNING", "BONUS"]]}, "$amount", 0]}},
            "paid": {"$sum": {"$cond": [{"$in": ["$type", ["PAYMENT", "ADVANCE"]]}, "$amount", 0]}},
        }}
    ]
    res = await db.labour_ledger.aggregate(pipeline).to_list(1)
    earned = res[0]["earned"] if res else 0
    paid = res[0]["paid"] if res else 0
    snap = {
        "labour_id": labour_id,
        "total_earned": earned,
        "total_paid": paid,
        "balance": earned - paid,
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
            "description": f"{body.type.title()} to {labour['name']}",
            "date": entry["date"], "party": labour["name"], "created_at": now_iso(),
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
async def list_expenses(site_id: Optional[str] = None, period: Optional[str] = None, user: dict = Depends(get_current_user)):
    q: dict = {"company_id": user["company_id"]}
    if user["role"] == "SUPERVISOR":
        q["site_id"] = {"$in": user.get("site_ids", [])}
    if site_id:
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
    construction_type: Literal["RESIDENTIAL", "COMMERCIAL", "INDUSTRIAL"] = "RESIDENTIAL"
    quality: Literal["BASIC", "STANDARD", "PREMIUM"] = "STANDARD"

QUALITY_RATE = {"BASIC": 1500, "STANDARD": 1800, "PREMIUM": 2400}  # ₹ per sqft
TYPE_FACTOR = {"RESIDENTIAL": 1.0, "COMMERCIAL": 1.15, "INDUSTRIAL": 1.25}

@v2_router.post("/estimates")
async def create_estimate(body: EstimateIn, user: dict = Depends(require_roles("CONTRACTOR"))):
    builtup = body.plot_area_sqft * body.floors
    # Material formulas (per sqft of built-up area)
    cement_bags = round(builtup * 0.4, 2)            # 0.4 bag / sqft
    steel_kg = round(builtup * 4.0, 2)               # 4 kg / sqft
    sand_cft = round(builtup * 0.85, 2)              # 0.85 cft / sqft
    aggregate_cft = round(builtup * 0.65, 2)         # 0.65 cft / sqft
    bricks_pcs = round(builtup * 8.0, 2)             # 8 / sqft

    rate_psf = QUALITY_RATE[body.quality] * TYPE_FACTOR[body.construction_type]
    total = round(builtup * rate_psf, 2)
    material_cost = round(total * 0.55, 2)
    labour_cost = round(total * 0.30, 2)
    overhead = round(total - material_cost - labour_cost, 2)

    doc = {
        "id": new_id(),
        "company_id": user["company_id"],
        "site_id": body.site_id,
        "name": body.name,
        "input": body.model_dump(),
        "builtup_sqft": builtup,
        "rate_per_sqft": rate_psf,
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
    await log_audit(user, "CREATE", "estimate", doc["id"], {"total": total})
    return doc

@v2_router.get("/estimates")
async def list_estimates(user: dict = Depends(require_roles("CONTRACTOR"))):
    return await db.estimates.find({"company_id": user["company_id"]}, {"_id": 0}).sort("created_at", -1).to_list(200)

@v2_router.get("/estimates/{est_id}")
async def get_estimate(est_id: str, user: dict = Depends(require_roles("CONTRACTOR", "CLIENT"))):
    q = {"id": est_id}
    if user["role"] == "CONTRACTOR":
        q["company_id"] = user["company_id"]
    e = await db.estimates.find_one(q, {"_id": 0})
    if not e:
        raise HTTPException(404, "Not found")
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
    q = {"id": boq_id}
    if user["role"] == "CONTRACTOR":
        q["company_id"] = user["company_id"]
    b = await db.boqs.find_one(q, {"_id": 0})
    if not b:
        raise HTTPException(404, "Not found")
    return b

# ---------- QR PAYMENT FLOW (UPI) ----------
UPI_ID_DEFAULT = "fk1571515@ybl"
PLAN_PRICES = {"FREE": 0, "PREMIUM": 499, "ENTERPRISE": 1199}

class PaymentRequestIn(BaseModel):
    plan: Literal["PREMIUM", "ENTERPRISE"]
    utr: str = Field(..., min_length=4, max_length=40)
    screenshot_url: Optional[str] = None
    note: Optional[str] = None

@v2_router.get("/payment/config")
async def payment_config(user: dict = Depends(get_current_user)):
    return {
        "upi_id": os.environ.get("UPI_ID", UPI_ID_DEFAULT),
        "payee_name": "Site Seva Pro",
        "prices": PLAN_PRICES,
    }

@v2_router.post("/payment/request")
async def create_payment_request(body: PaymentRequestIn, user: dict = Depends(require_roles("CONTRACTOR"))):
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
    await db.payments.insert_one({
        "id": new_id(), "company_id": p["company_id"], "site_id": None,
        "type": "SUBSCRIPTION", "amount": p["amount"],
        "description": f"{p['plan']} plan via UPI · UTR {p['utr']}",
        "date": now_iso()[:10], "created_at": now_iso(),
    })
    await db.payment_requests.update_one({"id": pid}, {"$set": {
        "status": "APPROVED", "approved_at": now_iso(), "approved_by": admin["id"],
    }})
    await db.notifications.insert_one({
        "id": new_id(), "user_id": p["user_id"], "company_id": p["company_id"],
        "title": "Subscription activated",
        "body": f"Your {p['plan']} plan is now active. Expires {expires[:10]}.",
        "type": "SUBSCRIPTION", "read": False, "created_at": now_iso(),
    })
    await log_audit(admin, "APPROVE", "payment_request", pid, {"plan": p["plan"], "amount": p["amount"]})
    return {"ok": True}

@v2_router.post("/admin/payments/{pid}/reject")
async def reject_payment(pid: str, reason: str = Query(""), admin: dict = Depends(require_roles("SUPER_ADMIN"))):
    p = await db.payment_requests.find_one({"id": pid}, {"_id": 0})
    if not p:
        raise HTTPException(404, "Not found")
    await db.payment_requests.update_one({"id": pid}, {"$set": {
        "status": "REJECTED", "rejected_at": now_iso(), "rejected_by": admin["id"], "reject_reason": reason,
    }})
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
