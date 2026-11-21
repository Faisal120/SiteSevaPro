"""Meta WhatsApp Cloud API webhook and admin delivery visibility."""
from __future__ import annotations

import hashlib
import hmac
import os

from fastapi import APIRouter, Depends, HTTPException, Query, Request
from fastapi.responses import PlainTextResponse

from core import db, require_roles
from services.outbound_notification_service import outbound_notification_service


router = APIRouter(prefix="/api", tags=["WhatsApp"])


@router.get("/whatsapp/webhook", response_class=PlainTextResponse)
async def verify_webhook(
    mode: str | None = Query(default=None, alias="hub.mode"),
    token: str | None = Query(default=None, alias="hub.verify_token"),
    challenge: str | None = Query(default=None, alias="hub.challenge"),
):
    expected = os.getenv("WHATSAPP_WEBHOOK_VERIFY_TOKEN", "")
    if not expected or mode != "subscribe" or not hmac.compare_digest(token or "", expected):
        raise HTTPException(403, "Webhook verification failed")
    return challenge or ""


@router.post("/whatsapp/webhook")
async def whatsapp_webhook(request: Request):
    raw = await request.body()
    app_secret = os.getenv("WHATSAPP_APP_SECRET", "").strip()
    signature = request.headers.get("x-hub-signature-256", "")
    if app_secret:
        expected = "sha256=" + hmac.new(
            app_secret.encode(),
            raw,
            hashlib.sha256,
        ).hexdigest()
        if not hmac.compare_digest(signature, expected):
            raise HTTPException(401, "Invalid webhook signature")

    payload = await request.json()
    for entry in payload.get("entry", []):
        for change in entry.get("changes", []):
            value = change.get("value") or {}
            for status in value.get("statuses", []):
                errors = status.get("errors") or []
                error = None
                if errors:
                    item = errors[0]
                    error = item.get("title") or item.get("message") or str(item)
                if status.get("id") and status.get("status"):
                    await outbound_notification_service.update_provider_status(
                        status["id"],
                        status["status"],
                        status.get("timestamp"),
                        error,
                    )
    return {"ok": True}


@router.get("/admin/whatsapp/status")
async def whatsapp_status(_: dict = Depends(require_roles("SUPER_ADMIN"))):
    required = {
        "access_token": bool(
            os.getenv("WHATSAPP_ACCESS_TOKEN") or os.getenv("WHATSAPP_API_TOKEN")
        ),
        "phone_number_id": bool(os.getenv("WHATSAPP_PHONE_NUMBER_ID")),
        "verify_token": bool(os.getenv("WHATSAPP_WEBHOOK_VERIFY_TOKEN")),
        "app_secret": bool(os.getenv("WHATSAPP_APP_SECRET")),
    }
    return {
        "configured": all(required.values()),
        "requirements": required,
        "api_version": os.getenv("WHATSAPP_API_VERSION", "v27.0"),
        "templates": {
            "credentials": os.getenv(
                "WHATSAPP_CREDENTIALS_TEMPLATE",
                "siteseva_account_credentials",
            ),
            "password_reset": os.getenv(
                "WHATSAPP_PASSWORD_RESET_TEMPLATE",
                "siteseva_password_reset",
            ),
            "approval": os.getenv(
                "WHATSAPP_APPROVAL_TEMPLATE",
                "siteseva_approval_update",
            ),
        },
    }


@router.get("/admin/whatsapp/deliveries")
async def whatsapp_deliveries(
    status: str | None = None,
    limit: int = Query(default=100, ge=1, le=500),
    _: dict = Depends(require_roles("SUPER_ADMIN")),
):
    query = {"status": status.upper()} if status else {}
    projection = {
        "_id": 0,
        "id": 1,
        "event": 1,
        "status": 1,
        "to": 1,
        "template_name": 1,
        "provider_message_id": 1,
        "last_error": 1,
        "attempts": 1,
        "created_at": 1,
        "updated_at": 1,
    }
    records = await db.outbound_notifications.find(
        query,
        projection,
    ).sort("created_at", -1).limit(limit).to_list(limit)
    for record in records:
        phone = record.pop("to", "")
        record["recipient"] = (
            f"{phone[:3]}••••••{phone[-3:]}" if len(phone) >= 6 else "••••"
        )
    return records
