"""Public, rate-limited website endpoints."""
from __future__ import annotations

from fastapi import APIRouter, Depends
from pydantic import BaseModel, EmailStr, Field

from core import db, new_id, now_iso, require_roles
from services.rate_limit import rate_limit, rate_limit_account
from services.plan_catalog import PLAN_CATALOG


router = APIRouter(prefix="/api", tags=["Public"])


@router.get("/public/plans")
async def public_plans():
    """Public, non-sensitive plan catalogue for marketing surfaces."""
    return [{key: value for key, value in plan.items() if key != "storage_gb"} for plan in PLAN_CATALOG.values()]


class ContactEnquiryIn(BaseModel):
    name: str = Field(min_length=2, max_length=120)
    email: EmailStr
    message: str = Field(min_length=10, max_length=4000)


@router.post("/public/enquiries", status_code=201, dependencies=[Depends(rate_limit("contact", 5, 3600))])
async def create_enquiry(body: ContactEnquiryIn):
    await rate_limit_account("contact-email", str(body.email), 3, 3600)
    enquiry = {
        "id": new_id(),
        "name": body.name.strip(),
        "email": str(body.email).lower(),
        "message": body.message.strip(),
        "status": "NEW",
        "created_at": now_iso(),
    }
    await db.contact_enquiries.insert_one(dict(enquiry))
    admins = await db.users.find({"role": "SUPER_ADMIN", "blocked": {"$ne": True}}, {"_id": 0, "id": 1}).to_list(20)
    if admins:
        await db.notifications.insert_many([{
            "id": new_id(), "user_id": admin["id"], "company_id": None,
            "title": "New website enquiry", "body": f"{enquiry['name']} sent a contact enquiry.",
            "type": "INFO", "read": False, "created_at": now_iso(),
        } for admin in admins])
    return {"ok": True, "message": "Thanks. Our team will get back to you shortly."}


@router.get("/admin/enquiries")
async def list_enquiries(_: dict = Depends(require_roles("SUPER_ADMIN"))):
    return await db.contact_enquiries.find({}, {"_id": 0}).sort("created_at", -1).limit(500).to_list(500)
