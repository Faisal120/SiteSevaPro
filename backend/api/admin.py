"""Supplementary super-admin management endpoints.

The dashboard, contractor list, and subscription list live in ``main.py``.
This router intentionally contains only non-overlapping detail/update routes.
"""

from fastapi import APIRouter, Depends, HTTPException

from core import db, hash_password, now_iso, require_roles
from models.subscription import SubscriptionUpdate
from services.admin_service import admin_service
from services.account_security import generate_temporary_password
from services.outbound_notification_service import outbound_notification_service


router = APIRouter(prefix="/api/admin", tags=["Admin"])


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
    password = generate_temporary_password()
    await db.users.update_one(
        {"id": contractor_id},
        {
            "$set": {
                "password_hash": hash_password(password),
                "must_change_password": True,
                "credentials_resent_at": now_iso(),
            },
            "$inc": {"password_version": 1},
        },
    )
    delivery = await outbound_notification_service.send_credentials(
        contractor,
        password,
    )
    await db.users.update_one(
        {"id": contractor_id},
        {
            "$set": {
                "credential_delivery_status": delivery.get("status"),
                "credential_delivery_id": delivery.get("id"),
            }
        },
    )
    return {"success": True, "whatsapp_delivery": delivery}


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
    _: dict = Depends(require_roles("SUPER_ADMIN")),
):
    return await admin_service.upgrade_subscription(company_id, body)


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
