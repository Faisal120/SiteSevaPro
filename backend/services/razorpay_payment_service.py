"""Authoritative Razorpay order, verification and fulfilment logic.

Only this module turns a captured provider payment into subscription benefits.
Its payment-id guard is intentionally persisted so both browser verification
and duplicate/out-of-order webhooks are harmless.
"""
from __future__ import annotations

from datetime import datetime, timedelta, timezone
import re
from typing import Any

from fastapi import HTTPException
from pymongo import ReturnDocument

from core import db, new_id, now_iso
from services.design_wallet_service import design_wallet_service
from services.plan_catalog import canonical_plan, plan_details
from services.razorpay_service import razorpay_gateway


PAID_PLANS = {"PREMIUM", "ENTERPRISE"}
PAYMENT_STATUSES = {"CREATED", "PENDING", "AUTHORIZED", "CAPTURED", "FAILED", "REFUNDED", "REFUND_REVIEW_REQUIRED"}


def _as_utc(value: str | None) -> datetime | None:
    if not value:
        return None
    try:
        return datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError:
        return None


def _safe_payment(payment: dict) -> dict:
    """Expose billing metadata, never provider signatures/notes/raw payloads."""
    fields = (
        "id", "plan", "amount", "amount_paise", "currency", "status", "created_at",
        "captured_at", "refunded_at", "subscription_expires_at", "razorpay_order_id",
        "razorpay_payment_id", "payment_method", "refund_status", "receipt_number",
    )
    return {field: payment.get(field) for field in fields if payment.get(field) is not None}


class RazorpayPaymentService:
    async def create_order(self, plan: str, user: dict) -> dict:
        plan = canonical_plan(plan)
        if plan not in PAID_PLANS:
            raise HTTPException(400, "Select a paid subscription plan")
        details = plan_details(plan)
        amount = int(details["price"])
        if amount <= 0:
            raise HTTPException(400, "Selected plan cannot be purchased")

        payment = {
            "id": new_id(),
            "provider": "RAZORPAY",
            "kind": "SUBSCRIPTION",
            "company_id": user["company_id"],
            "user_id": user["id"],
            "plan": plan,
            "amount": amount,
            "amount_paise": amount * 100,
            "currency": "INR",
            "razorpay_mode": razorpay_gateway.mode(),
            "status": "CREATED",
            "receipt_number": f"SSP-{new_id().replace('-', '')[:16].upper()}",
            "created_at": now_iso(),
        }
        await db.subscription_payments.insert_one(dict(payment))
        try:
            order = await razorpay_gateway.create_order({
                "amount": payment["amount_paise"], "currency": "INR",
                "receipt": payment["receipt_number"], "payment_capture": 1,
                "notes": {"site_seva_payment_id": payment["id"], "company_id": user["company_id"], "plan": plan},
            })
        except HTTPException:
            await db.subscription_payments.update_one({"id": payment["id"]}, {"$set": {"status": "FAILED", "failed_at": now_iso(), "failure_reason": "ORDER_CREATION_FAILED"}})
            raise
        order_id = str(order.get("id") or "")
        if not order_id:
            await db.subscription_payments.update_one({"id": payment["id"]}, {"$set": {"status": "FAILED", "failed_at": now_iso(), "failure_reason": "INVALID_PROVIDER_ORDER"}})
            raise HTTPException(502, "Payment provider returned an invalid order")
        await db.subscription_payments.update_one(
            {"id": payment["id"]}, {"$set": {"razorpay_order_id": order_id, "status": "PENDING", "provider_order_created_at": now_iso()}}
        )
        return {"payment_id": payment["id"], "order_id": order_id, "amount": payment["amount_paise"], "currency": "INR", "key_id": razorpay_gateway.public_key_id(), "plan": plan}

    async def verify_browser_payment(self, order_id: str, payment_id: str, signature: str, user: dict) -> dict:
        payment = await db.subscription_payments.find_one({"razorpay_order_id": order_id, "company_id": user["company_id"]}, {"_id": 0})
        if not payment:
            raise HTTPException(404, "Payment order not found")
        if payment.get("user_id") != user["id"]:
            raise HTTPException(403, "Payment order does not belong to this account")
        if payment.get("status") in {"CAPTURED", "REFUNDED", "REFUND_REVIEW_REQUIRED"}:
            return {"status": payment["status"], "payment": _safe_payment(payment), "idempotent": True}
        razorpay_gateway.verify_payment_signature(order_id, payment_id, signature)
        provider_payment = await razorpay_gateway.fetch_payment(payment_id)
        await self._validate_provider_payment(payment, provider_payment, order_id)
        result = await self._record_and_fulfil(payment, provider_payment, source="BROWSER")
        return result

    async def _validate_provider_payment(self, payment: dict, provider: dict, order_id: str) -> None:
        if str(provider.get("order_id") or "") != order_id:
            raise HTTPException(400, "Payment does not belong to this order")
        if int(provider.get("amount") or 0) != int(payment["amount_paise"]):
            raise HTTPException(400, "Payment amount verification failed")
        if str(provider.get("currency") or "").upper() != "INR":
            raise HTTPException(400, "Payment currency verification failed")
        if str(provider.get("status") or "").lower() != "captured":
            raise HTTPException(409, "Payment is awaiting capture")

    async def _record_and_fulfil(self, payment: dict, provider: dict, source: str) -> dict:
        payment_id = str(provider.get("id") or "")
        if not payment_id:
            raise HTTPException(502, "Payment provider returned an invalid payment")
        # A provider payment may be associated with only one internal record.
        claimed = await db.subscription_payments.find_one_and_update(
            {"id": payment["id"], "status": {"$in": ["CREATED", "PENDING", "AUTHORIZED", "FULFILLING"]}},
            {"$set": {"razorpay_payment_id": payment_id, "payment_method": provider.get("method"), "status": "FULFILLING", "verified_at": now_iso(), "verification_source": source}},
            return_document=ReturnDocument.AFTER,
        )
        if claimed is None:
            current = await db.subscription_payments.find_one({"id": payment["id"]}, {"_id": 0})
            return {"status": current.get("status", "PENDING"), "payment": _safe_payment(current or {}), "idempotent": True}
        return await self._fulfil(claimed)

    async def _fulfil(self, payment: dict) -> dict:
        """Applies one payment once. Safe to call again after a process restart."""
        existing = await db.subscription_payments.find_one({"id": payment["id"]}, {"_id": 0}) or payment
        if existing.get("status") == "CAPTURED":
            return {"status": "CAPTURED", "payment": _safe_payment(existing), "idempotent": True}

        now = datetime.now(timezone.utc)
        current = await db.subscriptions.find_one({"company_id": payment["company_id"]}, {"_id": 0}) or {}
        current_expiry = _as_utc(current.get("expires_at") or current.get("trial_expiry"))
        start = current_expiry if current.get("status") == "ACTIVE" and current_expiry and current_expiry > now else now
        expires = start + timedelta(days=30)
        details = plan_details(payment["plan"])

        # The applied_payment_ids condition makes the subscription extension idempotent.
        updated = await db.subscriptions.find_one_and_update(
            {"company_id": payment["company_id"], "applied_payment_ids": {"$ne": payment["id"]}},
            {"$set": {"company_id": payment["company_id"], "plan": payment["plan"], "status": "ACTIVE", "started_at": now_iso(), "expires_at": expires.isoformat(), "amount": payment["amount"], "max_sites": details["max_sites"], "max_supervisors": details["max_supervisors"], "storage_gb": details["storage_gb"], "trial": False, "updated_at": now_iso()}, "$addToSet": {"applied_payment_ids": payment["id"]}},
            upsert=True, return_document=ReturnDocument.AFTER,
        )
        # Mongo's result with an already applied payment is None; retrieve it without changing expiry.
        if updated is None:
            updated = await db.subscriptions.find_one({"company_id": payment["company_id"]}, {"_id": 0}) or {}

        # A separate unique grant record prevents duplicate credit grants after retries.
        grant = await db.subscription_credit_grants.find_one_and_update(
            {"payment_id": payment["id"], "status": {"$in": ["PENDING", "FAILED"]}},
            {"$set": {"status": "PROCESSING", "processing_at": now_iso()}, "$setOnInsert": {"payment_id": payment["id"], "company_id": payment["company_id"], "credits": details["monthly_design_credits"], "created_at": now_iso()}},
            upsert=True, return_document=ReturnDocument.BEFORE,
        )
        if grant is None or grant.get("status") in {"PENDING", "FAILED"}:
            await design_wallet_service.balance(payment["company_id"])
            try:
                await design_wallet_service.add(payment["company_id"], details["monthly_design_credits"], f"{payment['plan']} subscription credits · Razorpay payment")
            except Exception:
                await db.subscription_credit_grants.update_one({"payment_id": payment["id"]}, {"$set": {"status": "FAILED", "failed_at": now_iso()}})
                raise
            await db.subscription_credit_grants.update_one({"payment_id": payment["id"]}, {"$set": {"status": "APPLIED", "applied_at": now_iso()}})

        await db.users.update_many({"company_id": payment["company_id"], "role": "CONTRACTOR"}, {"$set": {"plan": payment["plan"], "updated_at": now_iso()}})
        await db.subscription_payments.update_one(
            {"id": payment["id"]}, {"$set": {"status": "CAPTURED", "captured_at": now_iso(), "subscription_expires_at": updated.get("expires_at")}}
        )
        await db.notifications.insert_one({"id": new_id(), "user_id": payment["user_id"], "company_id": payment["company_id"], "title": "Subscription activated", "body": f"Your {payment['plan']} plan is active until {str(updated.get('expires_at', ''))[:10]}.", "type": "SUBSCRIPTION", "read": False, "created_at": now_iso()})
        final = await db.subscription_payments.find_one({"id": payment["id"]}, {"_id": 0}) or payment
        return {"status": "CAPTURED", "payment": _safe_payment(final), "idempotent": False}

    async def status(self, payment_id: str, user: dict) -> dict:
        payment = await db.subscription_payments.find_one({"id": payment_id, "company_id": user["company_id"]}, {"_id": 0})
        if not payment:
            raise HTTPException(404, "Payment not found")
        return _safe_payment(payment)

    async def history(self, user: dict) -> list[dict]:
        rows = await db.subscription_payments.find({"company_id": user["company_id"]}, {"_id": 0}).sort("created_at", -1).limit(100).to_list(100)
        return [_safe_payment(row) for row in rows]

    async def admin_list(self, filters: dict[str, str | None]) -> dict:
        query: dict[str, Any] = {}
        for key in ("status", "plan", "company_id"):
            if filters.get(key):
                query[key] = filters[key]
        if filters.get("company"):
            company_rows = await db.companies.find(
                {"$or": [{"name": {"$regex": re.escape(str(filters["company"])), "$options": "i"}}, {"company_name": {"$regex": re.escape(str(filters["company"])), "$options": "i"}}]},
                {"_id": 0, "id": 1},
            ).limit(100).to_list(100)
            query["company_id"] = {"$in": [row["id"] for row in company_rows]}
        if filters.get("from") or filters.get("to"):
            query["created_at"] = {}
            if filters.get("from"):
                query["created_at"]["$gte"] = str(filters["from"])
            if filters.get("to"):
                query["created_at"]["$lt"] = f"{filters['to']}T23:59:59+00:00"
        rows = await db.subscription_payments.find(query, {"_id": 0, "provider_signature": 0, "provider_payload": 0}).sort("created_at", -1).limit(500).to_list(500)
        company_ids = list({row.get("company_id") for row in rows if row.get("company_id")})
        companies = await db.companies.find({"id": {"$in": company_ids}}, {"_id": 0, "id": 1, "name": 1, "company_name": 1}).to_list(len(company_ids) or 1)
        company_names = {company["id"]: company.get("name") or company.get("company_name") for company in companies}
        items = [{**_safe_payment(row), "company_id": row.get("company_id"), "company_name": company_names.get(row.get("company_id"), "—"), "user_id": row.get("user_id")} for row in rows]
        captured = sum(row.get("amount", 0) for row in rows if row.get("status") == "CAPTURED")
        refunded = sum(row.get("amount", 0) for row in rows if row.get("status") in {"REFUNDED", "REFUND_REVIEW_REQUIRED"})
        pending = sum(row.get("amount", 0) for row in rows if row.get("status") in {"CREATED", "PENDING", "AUTHORIZED", "FULFILLING"})
        return {"items": items, "totals": {"successful": captured, "refunded": refunded, "pending": pending}}

    async def receipt(self, payment_id: str, user: dict) -> dict:
        payment = await db.subscription_payments.find_one({"id": payment_id, "company_id": user["company_id"]}, {"_id": 0})
        if not payment or payment.get("status") not in {"CAPTURED", "REFUNDED", "REFUND_REVIEW_REQUIRED"}:
            raise HTTPException(404, "Receipt not available")
        return _safe_payment(payment)

    async def handle_webhook(self, event_type: str, event_id: str, payload: dict) -> dict:
        existing = await db.razorpay_webhook_events.find_one_and_update(
            {"event_id": event_id}, {"$setOnInsert": {"event_id": event_id, "event_type": event_type, "received_at": now_iso(), "status": "RECEIVED"}}, upsert=True, return_document=ReturnDocument.BEFORE
        )
        if existing is not None:
            return {"ok": True, "duplicate": True}
        payload_entities = payload.get("payload") or {}
        entity = (payload_entities.get("payment") or {}).get("entity") or {}
        order_id = str(entity.get("order_id") or "")
        provider_payment_id = str(entity.get("id") or "")
        payment = await db.subscription_payments.find_one({"razorpay_order_id": order_id}, {"_id": 0}) if order_id else None
        if event_type == "payment.failed" and payment:
            await db.subscription_payments.update_one({"id": payment["id"], "status": {"$nin": ["CAPTURED", "REFUNDED", "REFUND_REVIEW_REQUIRED"]}}, {"$set": {"status": "FAILED", "failed_at": now_iso(), "failure_reason": "PROVIDER_FAILED"}})
        elif event_type in {"payment.authorized", "payment.captured", "order.paid"} and payment and provider_payment_id:
            # Always fetch the provider object: webhook bodies are notifications, not proof of amount/capture.
            provider = await razorpay_gateway.fetch_payment(provider_payment_id)
            if str(provider.get("status", "")).lower() == "captured":
                await self._validate_provider_payment(payment, provider, order_id)
                await self._record_and_fulfil(payment, provider, source="WEBHOOK")
            else:
                await db.subscription_payments.update_one({"id": payment["id"], "status": {"$in": ["CREATED", "PENDING"]}}, {"$set": {"status": "AUTHORIZED", "authorized_at": now_iso()}})
        elif event_type == "refund.processed":
            refund = ((payload.get("payload") or {}).get("refund") or {}).get("entity") or {}
            refund_payment_id = str(refund.get("payment_id") or provider_payment_id)
            if refund_payment_id:
                # No automatic entitlement removal: the owner has not approved a refund policy.
                await db.subscription_payments.update_one({"razorpay_payment_id": refund_payment_id}, {"$set": {"status": "REFUND_REVIEW_REQUIRED", "refund_status": "PROCESSED", "refunded_at": now_iso(), "razorpay_refund_id": refund.get("id")}})
        await db.razorpay_webhook_events.update_one({"event_id": event_id}, {"$set": {"status": "PROCESSED", "processed_at": now_iso()}})
        return {"ok": True, "duplicate": False}


razorpay_payment_service = RazorpayPaymentService()
