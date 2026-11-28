"""Supplementary super-admin management endpoints.

The dashboard, contractor list, and subscription list live in ``main.py``.
This router intentionally contains only non-overlapping detail/update routes.
"""

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field

from core import db, now_iso, require_roles
from models.subscription import SubscriptionUpdate
from services.admin_service import admin_service
from services.account_security import normalize_phone
from services.outbound_notification_service import outbound_notification_service
from repositories.audit_repository import audit_repository


router = APIRouter(prefix="/api/admin", tags=["Admin"])


class WhatsAppNumberIn(BaseModel):
    phone: str = Field(min_length=8, max_length=24)


@router.get("/contractors/{contractor_id}")
async def contractor(
    contractor_id: str,
    _: dict = Depends(require_roles("SUPER_ADMIN")),
):
    return await admin_service.contractor_details(contractor_id)


@router.post("/contractors/{contractor_id}/resend-credentials")
async def resend_contractor_credentials(
    contractor_id: str,
    _: dict = Depends(require_roles("SUPER_ADMIN")),
):
    contractor = await db.users.find_one(
        {"id": contractor_id, "role": "CONTRACTOR"},
        {"_id": 0},
    )
    if not contractor:
        raise HTTPException(404, "Contractor not found")
    if not contractor.get("password_setup_required"):
        return {"success": False, "status": "ACTIVE", "message": "Active accounts must use password recovery; their password was not changed."}
    delivery = await outbound_notification_service.send_account_approved(contractor)
    await db.users.update_one(
        {"id": contractor_id},
        {
            "$set": {
                "credential_delivery_status": delivery.get("status"),
                "credential_delivery_id": delivery.get("id"),
                "credentials_resent_at": now_iso(),
            }
        },
    )
    await audit_repository.log("ADMIN_RESEND_ACTIVATION_NOTIFICATION", "Activation notification resent", account_id=contractor_id, outcome=delivery.get("status", "UNKNOWN"))
    return {"success": True, "whatsapp_delivery": delivery}


@router.patch("/contractors/{contractor_id}/whatsapp")
async def update_contractor_whatsapp(
    contractor_id: str,
    body: WhatsAppNumberIn,
    _: dict = Depends(require_roles("SUPER_ADMIN")),
):
    try:
        phone = normalize_phone(body.phone)
    except ValueError as error:
        raise HTTPException(400, str(error)) from error
    result = await db.users.update_one(
        {"id": contractor_id, "role": "CONTRACTOR"},
        {"$set": {"phone": phone, "whatsapp": phone, "updated_at": now_iso()}},
    )
    if result.matched_count == 0:
        raise HTTPException(404, "Contractor not found")
    return {"success": True, "phone": phone}


@router.put("/contractors/{contractor_id}/suspend")
async def suspend(
    contractor_id: str,
    _: dict = Depends(require_roles("SUPER_ADMIN")),
):
    return await admin_service.suspend(contractor_id)


@router.put("/contractors/{contractor_id}/activate")
async def activate(
    contractor_id: str,
    _: dict = Depends(require_roles("SUPER_ADMIN")),
):
    return await admin_service.activate(contractor_id)


@router.put("/subscriptions/{company_id}")
async def upgrade(
    company_id: str,
    body: SubscriptionUpdate,
    admin: dict = Depends(require_roles("SUPER_ADMIN")),
):
    # Retained as an explicit deprecation response so existing clients cannot
    # turn an unverified request into paid access. Existing subscriptions and
    # the separate expiry/admin operations remain unchanged.
    _ = (company_id, body, admin)
    raise HTTPException(410, "Manual subscription activation is retired. Paid plans activate after verified Razorpay capture.")


@router.put("/subscriptions/{company_id}/expire")
async def expire(
    company_id: str,
    _: dict = Depends(require_roles("SUPER_ADMIN")),
):
    return await admin_service.expire_subscription(company_id)


@router.get("/analytics")
async def analytics(_: dict = Depends(require_roles("SUPER_ADMIN"))):
    return await admin_service.analytics()


@router.get("/logs")
async def logs(_: dict = Depends(require_roles("SUPER_ADMIN"))):
    return await admin_service.logs()
