"""Durable, idempotent Razorpay subscription fulfilment.

Mongo transactions are not available on every development deployment (and must
not be assumed for a standalone Mongo instance).  This service therefore uses
short database-backed leases plus per-payment idempotency records.  Every
side-effect is independently replay-safe, so a worker crash can be resumed
without adding a second month, credit grant, or notification.
"""
from __future__ import annotations

import re
from datetime import datetime, timedelta, timezone
from typing import Any

from fastapi import HTTPException
from pymongo import ReturnDocument
from pymongo.errors import DuplicateKeyError

from core import db, new_id, now_iso
from services.design_wallet_service import design_wallet_service
from services.plan_catalog import canonical_plan, plan_details
from services.razorpay_service import razorpay_gateway


PAID_PLANS = {"PREMIUM", "ENTERPRISE"}
LEASE_SECONDS = 300
WEBHOOK_TTL_DAYS = 180


def _utc_now() -> datetime:
    return datetime.now(timezone.utc)


def _as_utc(value: str | None) -> datetime | None:
    if not value:
        return None
    try:
        parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
        return parsed if parsed.tzinfo else parsed.replace(tzinfo=timezone.utc)
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
        mode = razorpay_gateway.mode()
        payment = {
            "id": new_id(), "provider": "RAZORPAY", "kind": "SUBSCRIPTION",
            "company_id": user["company_id"], "user_id": user["id"], "plan": plan,
            "amount": amount, "amount_paise": amount * 100, "currency": "INR",
            "razorpay_mode": mode, "status": "CREATED",
            "receipt_number": f"SSP-{new_id().replace('-', '')[:16].upper()}",
            "created_at": now_iso(),
        }
        await db.subscription_payments.insert_one(dict(payment))
        try:
            order = await razorpay_gateway.create_order({
                "amount": payment["amount_paise"], "currency": "INR", "receipt": payment["receipt_number"],
                "payment_capture": 1,
                "notes": {"site_seva_payment_id": payment["id"], "company_id": user["company_id"], "plan": plan, "mode": mode},
            })
        except HTTPException:
            await db.subscription_payments.update_one({"id": payment["id"]}, {"$set": {"status": "FAILED", "failed_at": now_iso(), "failure_reason": "ORDER_CREATION_FAILED"}})
            raise
        order_id = str(order.get("id") or "")
        if not order_id:
            await db.subscription_payments.update_one({"id": payment["id"]}, {"$set": {"status": "FAILED", "failed_at": now_iso(), "failure_reason": "INVALID_PROVIDER_ORDER"}})
            raise HTTPException(502, "Payment provider returned an invalid order")
        await db.subscription_payments.update_one({"id": payment["id"]}, {"$set": {"razorpay_order_id": order_id, "status": "PENDING", "provider_order_created_at": now_iso()}})
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
        return await self._record_and_fulfil(payment, provider_payment, source="BROWSER")

    async def _validate_provider_payment(self, payment: dict, provider: dict, order_id: str) -> None:
        if payment.get("razorpay_mode") != razorpay_gateway.mode():
            raise HTTPException(409, "Payment environment does not match the current gateway mode")
        if str(provider.get("order_id") or "") != order_id:
            raise HTTPException(400, "Payment does not belong to this order")
        if int(provider.get("amount") or 0) != int(payment["amount_paise"]):
            raise HTTPException(400, "Payment amount verification failed")
        if str(provider.get("currency") or "").upper() != "INR":
            raise HTTPException(400, "Payment currency verification failed")
        if str(provider.get("status") or "").lower() != "captured":
            raise HTTPException(409, "Payment is awaiting capture")

    async def _record_and_fulfil(self, payment: dict, provider: dict, source: str) -> dict:
        provider_id = str(provider.get("id") or "")
        if not provider_id:
            raise HTTPException(502, "Payment provider returned an invalid payment")
        current = await db.subscription_payments.find_one({"id": payment["id"]}, {"_id": 0})
        if not current:
            raise HTTPException(404, "Payment order not found")
        if current.get("status") in {"CAPTURED", "REFUNDED", "REFUND_REVIEW_REQUIRED"}:
            return {"status": current["status"], "payment": _safe_payment(current), "idempotent": True}
        existing_provider_id = current.get("razorpay_payment_id")
        if existing_provider_id and existing_provider_id != provider_id:
            raise HTTPException(409, "A different payment is already being processed for this order")

        # A previously failed callback can be corrected by a later provider
        # capture.  A captured payment id is immutable once recorded.
        try:
            recorded = await db.subscription_payments.find_one_and_update(
                {
                    "id": current["id"],
                    # Do not regress a concurrently captured/refunded payment.
                    "status": {"$in": ["CREATED", "PENDING", "AUTHORIZED", "FAILED", "FULFILLMENT_FAILED", "FULFILLING"]},
                    "$or": [{"razorpay_payment_id": {"$exists": False}}, {"razorpay_payment_id": provider_id}],
                },
                {"$set": {"razorpay_payment_id": provider_id, "payment_method": provider.get("method"), "status": "FULFILLING", "verified_at": now_iso(), "verification_source": source, "last_provider_status": "captured"}},
                return_document=ReturnDocument.AFTER,
            )
        except DuplicateKeyError as error:
            # The provider payment id has already been bound to another
            # internal order. Never fulfil it a second time.
            raise HTTPException(409, "Payment is already associated with another order") from error
        if not recorded:
            latest = await db.subscription_payments.find_one({"id": current["id"]}, {"_id": 0}) or current
            return {"status": latest.get("status", "PENDING"), "payment": _safe_payment(latest), "idempotent": True}
        return await self._resume_fulfilment(recorded)

    async def _acquire_payment_lease(self, payment_id: str) -> tuple[dict | None, str]:
        lease_id = new_id()
        now = _utc_now()
        payment = await db.subscription_payments.find_one_and_update(
            {
                "id": payment_id,
                "status": {"$in": ["PENDING", "AUTHORIZED", "FAILED", "FULFILLMENT_FAILED", "FULFILLING"]},
                "$or": [
                    {"fulfilment_lease_expires_at": {"$exists": False}},
                    {"fulfilment_lease_expires_at": {"$lte": now}},
                ],
            },
            {"$set": {"status": "FULFILLING", "fulfilment_lease_id": lease_id, "fulfilment_lease_expires_at": now + timedelta(seconds=LEASE_SECONDS), "fulfilment_started_at": now_iso()}},
            return_document=ReturnDocument.AFTER,
        )
        return payment, lease_id

    async def _resume_fulfilment(self, payment: dict) -> dict:
        if payment.get("status") == "CAPTURED":
            return {"status": "CAPTURED", "payment": _safe_payment(payment), "idempotent": True}
        claimed, lease_id = await self._acquire_payment_lease(payment["id"])
        if not claimed:
            current = await db.subscription_payments.find_one({"id": payment["id"]}, {"_id": 0}) or payment
            return {"status": current.get("status", "FULFILLING"), "payment": _safe_payment(current), "idempotent": True}
        try:
            return await self._fulfil(claimed, lease_id)
        except Exception:
            await db.subscription_payments.update_one(
                {"id": claimed["id"], "fulfilment_lease_id": lease_id, "status": "FULFILLING"},
                {"$set": {"status": "FULFILLMENT_FAILED", "fulfilment_failed_at": now_iso()}, "$unset": {"fulfilment_lease_id": "", "fulfilment_lease_expires_at": ""}},
            )
            raise

    async def _acquire_company_lock(self, company_id: str, owner: str) -> bool:
        now = _utc_now()
        lock = await db.subscription_fulfilment_locks.find_one({"company_id": company_id}, {"_id": 0})
        if lock is None:
            try:
                await db.subscription_fulfilment_locks.insert_one({"company_id": company_id, "lease_id": owner, "lease_expires_at": now + timedelta(seconds=LEASE_SECONDS), "updated_at": now_iso()})
                return True
            except DuplicateKeyError:
                return False
        claim = await db.subscription_fulfilment_locks.find_one_and_update(
            {"company_id": company_id, "$or": [{"lease_id": owner}, {"lease_expires_at": {"$lte": now}}]},
            {"$set": {"lease_id": owner, "lease_expires_at": now + timedelta(seconds=LEASE_SECONDS), "updated_at": now_iso()}},
            return_document=ReturnDocument.AFTER,
        )
        return claim is not None

    async def _release_company_lock(self, company_id: str, owner: str) -> None:
        await db.subscription_fulfilment_locks.update_one(
            {"company_id": company_id, "lease_id": owner},
            {"$set": {"lease_expires_at": _utc_now() - timedelta(seconds=1), "released_at": now_iso()}},
        )

    async def _apply_subscription(self, payment: dict) -> dict:
        """Apply exactly one 30-day entitlement while holding the company lock."""
        existing = await db.subscriptions.find_one({"company_id": payment["company_id"]})
        if existing and payment["id"] in existing.get("applied_payment_ids", []):
            return existing
        now = _utc_now()
        current_expiry = _as_utc((existing or {}).get("expires_at") or (existing or {}).get("trial_expiry"))
        start = current_expiry if (existing or {}).get("status") == "ACTIVE" and current_expiry and current_expiry > now else now
        expires = start + timedelta(days=30)
        details = plan_details(payment["plan"])
        update = {
            "$set": {"company_id": payment["company_id"], "plan": payment["plan"], "status": "ACTIVE", "started_at": now_iso(), "expires_at": expires.isoformat(), "amount": payment["amount"], "max_sites": details["max_sites"], "max_supervisors": details["max_supervisors"], "storage_gb": details["storage_gb"], "trial": False, "updated_at": now_iso()},
            "$addToSet": {"applied_payment_ids": payment["id"]},
        }
        if existing:
            updated = await db.subscriptions.find_one_and_update(
                {"_id": existing["_id"], "applied_payment_ids": {"$ne": payment["id"]}}, update, return_document=ReturnDocument.AFTER
            )
            return updated or await db.subscriptions.find_one({"_id": existing["_id"]})
        # A deterministic id plus a unique index is a second line of defence
        # if a process is paused long enough for its company lease to expire.
        # It avoids an upsert race without requiring a transaction-capable
        # Mongo deployment.
        document = {"id": f"subscription:{payment['company_id']}", **update["$set"], "applied_payment_ids": [payment["id"]]}
        try:
            await db.subscriptions.insert_one(document)
            return document
        except DuplicateKeyError:
            # A legacy/non-unique deployment raced a create; do not create a
            # second entitlement document. The next lease holder resumes it.
            raced = await db.subscriptions.find_one({"company_id": payment["company_id"]})
            if not raced:
                raise
            return await self._apply_subscription(payment)

    async def _apply_credits(self, payment: dict) -> None:
        details = plan_details(payment["plan"])
        grants = db.subscription_credit_grants
        grant = await grants.find_one({"payment_id": payment["id"]})
        if grant and grant.get("status") == "APPLIED":
            return
        if grant is None:
            try:
                await grants.insert_one({"payment_id": payment["id"], "company_id": payment["company_id"], "credits": details["monthly_design_credits"], "status": "PENDING", "created_at": now_iso()})
            except DuplicateKeyError:
                pass
        grant = await grants.find_one_and_update(
            {"payment_id": payment["id"], "$or": [{"status": {"$in": ["PENDING", "FAILED"]}}, {"status": "PROCESSING", "processing_lease_expires_at": {"$lte": _utc_now()}}]},
            {"$set": {"status": "PROCESSING", "processing_at": now_iso(), "processing_lease_expires_at": _utc_now() + timedelta(seconds=LEASE_SECONDS)}},
            return_document=ReturnDocument.AFTER,
        )
        if not grant:
            current = await grants.find_one({"payment_id": payment["id"]}) or {}
            if current.get("status") == "APPLIED":
                return
            raise HTTPException(503, "Payment fulfilment is already in progress")
        # Ensures the legacy wallet exists. Its welcome-credit behaviour is
        # preserved; the paid grant below is atomic and payment-idempotent.
        await design_wallet_service.balance(payment["company_id"])
        wallet_result = await db.design_wallets.update_one(
            {"company_id": payment["company_id"], "subscription_credit_grant_ids": {"$ne": payment["id"]}},
            {"$inc": {"credits": details["monthly_design_credits"]}, "$addToSet": {"subscription_credit_grant_ids": payment["id"]}, "$set": {"updated_at": now_iso()}},
        )
        if wallet_result.matched_count != 1:
            # The process may have died after the atomic wallet increment but
            # before recording the grant.  The wallet marker is the durable
            # source of truth in that narrow window, so finish the audit trail
            # rather than issuing credits again.
            wallet = await db.design_wallets.find_one(
                {
                    "company_id": payment["company_id"],
                    "subscription_credit_grant_ids": payment["id"],
                },
                {"_id": 1},
            )
            if not wallet:
                await grants.update_one({"payment_id": payment["id"]}, {"$set": {"status": "FAILED", "failed_at": now_iso()}})
                raise HTTPException(500, "Design wallet could not be updated")
        # A crash after the wallet increment is harmless: the marker prevents
        # another increment and this upsert recreates only the audit row.
        await db.design_transactions.find_one_and_update(
            {"subscription_payment_id": payment["id"]},
            {"$setOnInsert": {"id": new_id(), "company_id": payment["company_id"], "credits": details["monthly_design_credits"], "type": "PURCHASE", "description": f"{payment['plan']} subscription credits · Razorpay payment", "subscription_payment_id": payment["id"], "created_at": now_iso()}},
            upsert=True,
        )
        await grants.update_one({"payment_id": payment["id"]}, {"$set": {"status": "APPLIED", "applied_at": now_iso()}, "$unset": {"processing_lease_expires_at": ""}})

    async def _ensure_notification(self, payment: dict, expires_at: str | None) -> None:
        await db.notifications.update_one(
            {"dedupe_key": f"subscription-activated:{payment['id']}"},
            {"$setOnInsert": {"id": new_id(), "dedupe_key": f"subscription-activated:{payment['id']}", "user_id": payment["user_id"], "company_id": payment["company_id"], "title": "Subscription activated", "body": f"Your {payment['plan']} plan is active until {str(expires_at or '')[:10]}.", "type": "SUBSCRIPTION", "read": False, "created_at": now_iso()}},
            upsert=True,
        )

    async def _fulfil(self, payment: dict, lease_id: str) -> dict:
        if not await self._acquire_company_lock(payment["company_id"], lease_id):
            # Another paid order for this company is extending the same
            # subscription. Release this payment's own lease so a browser
            # poll or webhook retry can continue as soon as that order ends.
            await db.subscription_payments.update_one(
                {"id": payment["id"], "fulfilment_lease_id": lease_id, "status": "FULFILLING"},
                {"$unset": {"fulfilment_lease_id": "", "fulfilment_lease_expires_at": ""}},
            )
            return {"status": "FULFILLING", "payment": _safe_payment(payment), "idempotent": True}
        try:
            subscription = await self._apply_subscription(payment)
            await self._apply_credits(payment)
            await db.users.update_many({"company_id": payment["company_id"], "role": "CONTRACTOR"}, {"$set": {"plan": payment["plan"], "updated_at": now_iso()}})
            await self._ensure_notification(payment, subscription.get("expires_at"))
            final = await db.subscription_payments.find_one_and_update(
                {"id": payment["id"], "fulfilment_lease_id": lease_id, "status": "FULFILLING"},
                {"$set": {"status": "CAPTURED", "captured_at": now_iso(), "subscription_expires_at": subscription.get("expires_at")}, "$unset": {"fulfilment_lease_id": "", "fulfilment_lease_expires_at": ""}},
                return_document=ReturnDocument.AFTER,
            )
            if not final:
                final = await db.subscription_payments.find_one({"id": payment["id"]}, {"_id": 0}) or payment
            return {"status": final.get("status", "FULFILLING"), "payment": _safe_payment(final), "idempotent": final.get("status") != "CAPTURED"}
        finally:
            await self._release_company_lock(payment["company_id"], lease_id)

    async def status(self, payment_id: str, user: dict) -> dict:
        payment = await db.subscription_payments.find_one({"id": payment_id, "company_id": user["company_id"]}, {"_id": 0})
        if not payment:
            raise HTTPException(404, "Payment not found")
        if payment.get("status") in {"FULFILLING", "FULFILLMENT_FAILED"} and payment.get("razorpay_payment_id"):
            result = await self._resume_fulfilment(payment)
            return result["payment"]
        return _safe_payment(payment)

    async def history(self, user: dict) -> list[dict]:
        rows = await db.subscription_payments.find({"company_id": user["company_id"]}, {"_id": 0}).sort("created_at", -1).limit(100).to_list(100)
        return [_safe_payment(row) for row in rows]

    async def admin_list(self, filters: dict[str, str | None]) -> dict:
        query: dict[str, Any] = {}
        for key in ("status", "plan", "company_id"):
            if filters.get(key): query[key] = filters[key]
        if filters.get("company"):
            company_rows = await db.companies.find({"$or": [{"name": {"$regex": re.escape(str(filters["company"])), "$options": "i"}}, {"company_name": {"$regex": re.escape(str(filters["company"])), "$options": "i"}}]}, {"_id": 0, "id": 1}).limit(100).to_list(100)
            query["company_id"] = {"$in": [row["id"] for row in company_rows]}
        if filters.get("from") or filters.get("to"):
            query["created_at"] = {}
            if filters.get("from"): query["created_at"]["$gte"] = str(filters["from"])
            if filters.get("to"): query["created_at"]["$lt"] = f"{filters['to']}T23:59:59+00:00"
        rows = await db.subscription_payments.find(query, {"_id": 0, "provider_signature": 0, "provider_payload": 0}).sort("created_at", -1).limit(500).to_list(500)
        company_ids = list({row.get("company_id") for row in rows if row.get("company_id")})
        companies = await db.companies.find({"id": {"$in": company_ids}}, {"_id": 0, "id": 1, "name": 1, "company_name": 1}).to_list(len(company_ids) or 1)
        names = {company["id"]: company.get("name") or company.get("company_name") for company in companies}
        items = [{**_safe_payment(row), "company_id": row.get("company_id"), "company_name": names.get(row.get("company_id"), "—"), "user_id": row.get("user_id")} for row in rows]
        return {"items": items, "totals": {"successful": sum(row.get("amount", 0) for row in rows if row.get("status") == "CAPTURED"), "refunded": sum(row.get("amount", 0) for row in rows if row.get("status") in {"REFUNDED", "REFUND_REVIEW_REQUIRED"}), "pending": sum(row.get("amount", 0) for row in rows if row.get("status") in {"CREATED", "PENDING", "AUTHORIZED", "FULFILLING", "FULFILLMENT_FAILED"})}}

    async def receipt(self, payment_id: str, user: dict) -> dict:
        payment = await db.subscription_payments.find_one({"id": payment_id, "company_id": user["company_id"]}, {"_id": 0})
        if not payment or payment.get("status") not in {"CAPTURED", "REFUNDED", "REFUND_REVIEW_REQUIRED"}:
            raise HTTPException(404, "Receipt not available")
        return _safe_payment(payment)

    async def _claim_webhook_event(self, event_type: str, event_id: str) -> tuple[dict | None, str]:
        now = _utc_now(); lease_id = new_id()
        event = await db.razorpay_webhook_events.find_one({"event_id": event_id})
        if event is None:
            try:
                await db.razorpay_webhook_events.insert_one({"event_id": event_id, "event_type": event_type, "status": "RECEIVED", "attempts": 0, "received_at": now, "expires_at": now + timedelta(days=WEBHOOK_TTL_DAYS)})
            except DuplicateKeyError:
                pass
        event = await db.razorpay_webhook_events.find_one({"event_id": event_id})
        if event and event.get("status") == "PROCESSED":
            return None, "PROCESSED"
        claim = await db.razorpay_webhook_events.find_one_and_update(
            {"event_id": event_id, "$or": [{"status": {"$in": ["RECEIVED", "FAILED"]}}, {"status": "PROCESSING", "processing_lease_expires_at": {"$lte": now}}]},
            {"$set": {"status": "PROCESSING", "processing_lease_id": lease_id, "processing_lease_expires_at": now + timedelta(seconds=LEASE_SECONDS), "last_started_at": now}, "$inc": {"attempts": 1}},
            return_document=ReturnDocument.AFTER,
        )
        return claim, lease_id

    async def _finish_webhook_event(self, event_id: str, lease_id: str, *, status: str, error: str | None = None) -> None:
        update: dict[str, Any] = {"status": status, "updated_at": _utc_now()}
        if status == "PROCESSED": update["processed_at"] = _utc_now()
        if error: update["last_error"] = error
        await db.razorpay_webhook_events.update_one({"event_id": event_id, "processing_lease_id": lease_id}, {"$set": update, "$unset": {"processing_lease_id": "", "processing_lease_expires_at": ""}})

    async def handle_webhook(self, event_type: str, event_id: str, payload: dict) -> dict:
        event, lease_id = await self._claim_webhook_event(event_type, event_id)
        if event is None:
            if lease_id == "PROCESSED": return {"ok": True, "duplicate": True}
            raise HTTPException(503, "Webhook event is already being processed")
        try:
            entities = payload.get("payload") or {}
            entity = (entities.get("payment") or {}).get("entity") or {}
            order_id = str(entity.get("order_id") or "")
            provider_payment_id = str(entity.get("id") or "")
            payment = await db.subscription_payments.find_one({"razorpay_order_id": order_id}, {"_id": 0}) if order_id else None
            result: dict | None = None
            if event_type == "payment.failed" and payment:
                # Late failures never replace captured or leased fulfilment.
                await db.subscription_payments.update_one({"id": payment["id"], "status": {"$in": ["CREATED", "PENDING", "AUTHORIZED", "FAILED"]}}, {"$set": {"status": "FAILED", "failed_at": now_iso(), "failure_reason": "PROVIDER_FAILED", "last_provider_status": "failed"}})
            elif event_type in {"payment.authorized", "payment.captured", "order.paid"} and payment and provider_payment_id:
                provider = await razorpay_gateway.fetch_payment(provider_payment_id)
                if str(provider.get("status", "")).lower() == "captured":
                    await self._validate_provider_payment(payment, provider, order_id)
                    result = await self._record_and_fulfil(payment, provider, source="WEBHOOK")
                    if result.get("status") != "CAPTURED":
                        raise HTTPException(503, "Payment fulfilment is in progress")
                else:
                    await db.subscription_payments.update_one({"id": payment["id"], "status": {"$in": ["CREATED", "PENDING"]}}, {"$set": {"status": "AUTHORIZED", "authorized_at": now_iso(), "last_provider_status": str(provider.get("status") or "authorized")}})
            elif event_type == "refund.processed":
                refund = (entities.get("refund") or {}).get("entity") or {}
                refund_payment_id = str(refund.get("payment_id") or provider_payment_id)
                if refund_payment_id:
                    await db.subscription_payments.update_one({"razorpay_payment_id": refund_payment_id, "status": {"$in": ["CAPTURED", "REFUNDED", "REFUND_REVIEW_REQUIRED"]}}, {"$set": {"status": "REFUND_REVIEW_REQUIRED", "refund_status": "PROCESSED", "refunded_at": now_iso(), "razorpay_refund_id": refund.get("id")}})
            await self._finish_webhook_event(event_id, lease_id, status="PROCESSED")
            return {"ok": True, "duplicate": False, "payment_status": (result or {}).get("status")}
        except Exception as error:
            await self._finish_webhook_event(event_id, lease_id, status="FAILED", error=type(error).__name__)
            raise


razorpay_payment_service = RazorpayPaymentService()
