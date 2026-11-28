import hashlib
from typing import Literal

from fastapi import APIRouter, Depends, Header, HTTPException, Request
from pydantic import BaseModel, Field

from core import (
    get_current_user,
    require_roles,
)

from models.payment import PaymentIn

from services.payment_service import payment_service
from services.razorpay_payment_service import razorpay_payment_service
from services.razorpay_service import razorpay_gateway


router = APIRouter(

    prefix="/api/payments",

    tags=["Payments"],

)


class RazorpayOrderIn(BaseModel):
    plan: Literal["PREMIUM", "ENTERPRISE", "PRO"]


class RazorpayVerifyIn(BaseModel):
    razorpay_order_id: str = Field(min_length=6, max_length=128)
    razorpay_payment_id: str = Field(min_length=6, max_length=128)
    razorpay_signature: str = Field(min_length=16, max_length=512)


@router.post("/subscription/orders")
async def create_subscription_order(
    body: RazorpayOrderIn,
    user=Depends(require_roles("CONTRACTOR")),
):
    """Creates a trusted, one-time Razorpay order for the selected paid plan."""
    return await razorpay_payment_service.create_order(body.plan, user)


@router.get("/subscription/checkout-availability")
async def subscription_checkout_availability(
    user=Depends(require_roles("CONTRACTOR")),
):
    """Frontend display hint; order creation still enforces this server-side."""
    return await razorpay_payment_service.checkout_availability(user)


@router.post("/subscription/verify")
async def verify_subscription_payment(
    body: RazorpayVerifyIn,
    user=Depends(require_roles("CONTRACTOR")),
):
    return await razorpay_payment_service.verify_browser_payment(
        body.razorpay_order_id,
        body.razorpay_payment_id,
        body.razorpay_signature,
        user,
    )


@router.get("/subscription/history")
async def subscription_payment_history(user=Depends(require_roles("CONTRACTOR"))):
    return await razorpay_payment_service.history(user)


@router.get("/subscription/{payment_id}")
async def subscription_payment_status(
    payment_id: str,
    user=Depends(require_roles("CONTRACTOR")),
):
    return await razorpay_payment_service.status(payment_id, user)


@router.get("/subscription/{payment_id}/receipt")
async def subscription_payment_receipt(
    payment_id: str,
    user=Depends(require_roles("CONTRACTOR")),
):
    # A client-side print/download layout uses this safe receipt payload. It
    # intentionally excludes provider signatures, raw events and payment notes.
    return await razorpay_payment_service.receipt(payment_id, user)


@router.get("/admin/subscriptions")
async def admin_subscription_payments(
    status: str | None = None,
    plan: str | None = None,
    company: str | None = None,
    company_id: str | None = None,
    date_from: str | None = None,
    date_to: str | None = None,
    _: dict = Depends(require_roles("SUPER_ADMIN")),
):
    return await razorpay_payment_service.admin_list({
        "status": status,
        "plan": plan,
        "company_id": company_id,
        "company": company,
        "from": date_from,
        "to": date_to,
    })


@router.post("/admin/subscriptions/reconcile-pending")
async def reconcile_pending_subscription_payments(
    _: dict = Depends(require_roles("SUPER_ADMIN")),
):
    return await razorpay_payment_service.reconcile_pending()


@router.post("/razorpay/webhook", include_in_schema=False)
async def razorpay_webhook(
    request: Request,
    signature: str | None = Header(default=None, alias="X-Razorpay-Signature"),
    event_header_id: str | None = Header(default=None, alias="X-Razorpay-Event-Id"),
):
    raw_body = await request.body()
    razorpay_gateway.verify_webhook_signature(raw_body, signature)
    try:
        payload = await request.json()
    except Exception as error:
        raise HTTPException(400, "Invalid webhook payload") from error
    if not isinstance(payload, dict):
        raise HTTPException(400, "Invalid webhook payload")
    event_type = str(payload.get("event") or "")
    supported = {"payment.authorized", "payment.captured", "payment.failed", "order.paid", "refund.processed"}
    if event_type not in supported:
        return {"ok": True, "ignored": True}
    # Razorpay's event id header is preferred. A hash gives deterministic
    # replay protection on integrations that do not send it.
    event_id = event_header_id or hashlib.sha256(raw_body).hexdigest()
    return await razorpay_payment_service.handle_webhook(event_type, event_id, payload)


@router.get("")
async def list_payments(

    site_id: str | None = None,

    user=Depends(
        get_current_user
    ),

):

    return await payment_service.list_payments(

        site_id,

        user,

    )


@router.post("")
async def create_payment(

    body: PaymentIn,

    user=Depends(

        require_roles(
            "CONTRACTOR"
        )

    ),

):

    return await payment_service.create_payment(

        body,

        user,

    )
