"""Real-Mongo integration tests for payment fulfilment durability.

Set MONGO_INTEGRATION_URL to an isolated disposable MongoDB database server to
run these tests.  They intentionally skip when none is supplied so developers
cannot accidentally point the suite at a local or production database.
"""
from __future__ import annotations

import asyncio
import os
import uuid
from datetime import datetime, timedelta, timezone

import pytest
from fastapi import HTTPException
from motor.motor_asyncio import AsyncIOMotorClient

INTEGRATION_URL = os.getenv("MONGO_INTEGRATION_URL", "").strip()

os.environ.setdefault("MONGO_URL", "mongodb://127.0.0.1:27018")
os.environ.setdefault("DB_NAME", "sitesevapro_razorpay_test")
os.environ.setdefault("JWT_SECRET", "test-jwt-secret")
os.environ.setdefault("SUPER_ADMIN_EMAIL", "admin@example.test")
os.environ.setdefault("SUPER_ADMIN_PASSWORD", "not-a-production-password")

if not INTEGRATION_URL:
    pytestmark = pytest.mark.skip(reason="set MONGO_INTEGRATION_URL to run real Mongo payment integration tests")

from services import razorpay_payment_service as payment_module
from services.plan_catalog import plan_details


def run(awaitable):
    return asyncio.run(awaitable)


@pytest.fixture
def mongo_db(monkeypatch):
    if not INTEGRATION_URL:
        pytest.skip("set MONGO_INTEGRATION_URL to run real Mongo payment integration tests")
    client = AsyncIOMotorClient(INTEGRATION_URL, serverSelectionTimeoutMS=3000)
    run(client.admin.command("ping"))
    database = client[f"siteseva_payment_it_{uuid.uuid4().hex}"]
    run(database.subscription_payments.create_index("id", unique=True))
    run(database.subscription_payments.create_index("razorpay_order_id", unique=True, sparse=True))
    run(database.subscription_payments.create_index("razorpay_payment_id", unique=True, sparse=True))
    run(database.subscription_fulfilment_locks.create_index("company_id", unique=True))
    run(database.subscription_credit_grants.create_index("payment_id", unique=True))
    run(database.design_transactions.create_index("subscription_payment_id", unique=True, sparse=True))
    run(database.notifications.create_index("dedupe_key", unique=True, sparse=True))
    run(database.razorpay_webhook_events.create_index("event_id", unique=True))

    monkeypatch.setattr(payment_module, "db", database)
    monkeypatch.setattr(payment_module.razorpay_gateway, "mode", lambda: "test")

    async def ensure_wallet(company_id: str):
        await database.design_wallets.update_one(
            {"company_id": company_id},
            {"$setOnInsert": {"company_id": company_id, "credits": 0}},
            upsert=True,
        )
        return await database.design_wallets.find_one({"company_id": company_id})

    monkeypatch.setattr(payment_module.design_wallet_service, "balance", ensure_wallet)
    try:
        yield database
    finally:
        run(client.drop_database(database.name))
        client.close()


def payment(payment_id: str, company_id: str = "company-1", *, status: str = "PENDING") -> dict:
    return {
        "id": payment_id,
        "company_id": company_id,
        "user_id": "contractor-1",
        "plan": "PREMIUM",
        "amount": 2999,
        "amount_paise": 299900,
        "currency": "INR",
        "razorpay_mode": "test",
        "razorpay_order_id": f"order_{payment_id}",
        "status": status,
        "created_at": datetime.now(timezone.utc).isoformat(),
    }


def provider(record: dict) -> dict:
    return {
        "id": f"pay_{record['id']}",
        "order_id": record["razorpay_order_id"],
        "amount": record["amount_paise"],
        "currency": "INR",
        "status": "captured",
        "method": "upi",
    }


def test_concurrent_browser_and_webhook_fulfil_once(mongo_db):
    async def scenario():
        record = payment("concurrent")
        await mongo_db.subscription_payments.insert_one(record)
        service = payment_module.RazorpayPaymentService()
        async def fetch(_payment_id):
            return provider(record)
        payment_module.razorpay_gateway.fetch_payment = fetch
        payment_module.razorpay_gateway.verify_payment_signature = lambda *_args: None
        webhook_payload = {"payload": {"payment": {"entity": {"id": "pay_concurrent", "order_id": record["razorpay_order_id"]}}}}
        results = await asyncio.gather(
            service.verify_browser_payment(record["razorpay_order_id"], "pay_concurrent", "test-signature", {"id": record["user_id"], "company_id": record["company_id"]}),
            service.handle_webhook("payment.captured", "evt-concurrent", webhook_payload),
            return_exceptions=True,
        )
        # A racing webhook can return retryable 503 while the browser worker
        # owns the lease. Re-delivery must complete it, never grant twice.
        if isinstance(results[1], HTTPException):
            await service.handle_webhook("payment.captured", "evt-concurrent", webhook_payload)
        # The losing caller may observe FULFILLING; a subsequent status poll
        # is the supported recovery mechanism.
        await service.status(record["id"], {"company_id": record["company_id"]})
        stored = await mongo_db.subscription_payments.find_one({"id": record["id"]})
        subscription = await mongo_db.subscriptions.find_one({"company_id": record["company_id"]})
        wallet = await mongo_db.design_wallets.find_one({"company_id": record["company_id"]})
        assert stored["status"] == "CAPTURED"
        assert subscription["applied_payment_ids"] == [record["id"]]
        assert wallet["subscription_credit_grant_ids"] == [record["id"]]
        assert wallet["credits"] == plan_details("PREMIUM")["monthly_design_credits"]
        assert await mongo_db.notifications.count_documents({"dedupe_key": f"subscription-activated:{record['id']}"}) == 1
    run(scenario())


def test_duplicate_event_and_failed_retry_are_recoverable(mongo_db, monkeypatch):
    async def scenario():
        record = payment("event-retry")
        await mongo_db.subscription_payments.insert_one(record)
        service = payment_module.RazorpayPaymentService()
        attempts = {"count": 0}

        async def fetch(_payment_id):
            attempts["count"] += 1
            if attempts["count"] == 1:
                raise HTTPException(502, "provider unavailable")
            return provider(record)

        monkeypatch.setattr(payment_module.razorpay_gateway, "fetch_payment", fetch)
        payload = {"payload": {"payment": {"entity": {"id": "pay_event-retry", "order_id": record["razorpay_order_id"]}}}}
        with pytest.raises(HTTPException):
            await service.handle_webhook("payment.captured", "evt-retry", payload)
        failed = await mongo_db.razorpay_webhook_events.find_one({"event_id": "evt-retry"})
        assert failed["status"] == "FAILED"
        assert failed["attempts"] == 1
        second = await service.handle_webhook("payment.captured", "evt-retry", payload)
        duplicate = await service.handle_webhook("payment.captured", "evt-retry", payload)
        # An out-of-order failure must not replace the verified capture.
        await service.handle_webhook("payment.failed", "evt-late-failure", payload)
        assert second["duplicate"] is False
        assert duplicate["duplicate"] is True
        assert (await mongo_db.subscription_payments.find_one({"id": record["id"]}))["status"] == "CAPTURED"
    run(scenario())


def test_interrupted_credit_grant_and_failed_payment_recover(mongo_db):
    async def scenario():
        record = payment("recovery", status="FAILED")
        record["razorpay_payment_id"] = "pay_recovery"
        await mongo_db.subscription_payments.insert_one(record)
        # Simulate a crash after credit increment but before grant/audit finish.
        await mongo_db.design_wallets.insert_one({"company_id": record["company_id"], "credits": 250, "subscription_credit_grant_ids": [record["id"]]})
        await mongo_db.subscription_credit_grants.insert_one({"payment_id": record["id"], "company_id": record["company_id"], "credits": 250, "status": "PROCESSING", "processing_lease_expires_at": datetime.now(timezone.utc) - timedelta(seconds=1)})
        service = payment_module.RazorpayPaymentService()
        result = await service._record_and_fulfil(record, provider(record), "WEBHOOK")
        stored = await mongo_db.subscription_payments.find_one({"id": record["id"]})
        wallet = await mongo_db.design_wallets.find_one({"company_id": record["company_id"]})
        grant = await mongo_db.subscription_credit_grants.find_one({"payment_id": record["id"]})
        assert result["status"] == "CAPTURED"
        assert stored["status"] == "CAPTURED"
        assert wallet["credits"] == 250
        assert grant["status"] == "APPLIED"
        assert await mongo_db.design_transactions.count_documents({"subscription_payment_id": record["id"]}) == 1
    run(scenario())


def test_concurrent_renewals_preserve_both_months(mongo_db):
    async def scenario():
        first, second = payment("renew-a"), payment("renew-b")
        await mongo_db.subscription_payments.insert_many([first, second])
        service = payment_module.RazorpayPaymentService()
        await asyncio.gather(
            service._record_and_fulfil(first, provider(first), "BROWSER"),
            service._record_and_fulfil(second, provider(second), "WEBHOOK"),
        )
        # Retry the one which observed the company lease while the other ran.
        for item in (first, second):
            await service.status(item["id"], {"company_id": item["company_id"]})
        subscription = await mongo_db.subscriptions.find_one({"company_id": first["company_id"]})
        assert set(subscription["applied_payment_ids"]) == {first["id"], second["id"]}
        expiry = datetime.fromisoformat(subscription["expires_at"])
        assert expiry >= datetime.now(timezone.utc) + timedelta(days=59)
    run(scenario())


def test_test_live_mode_isolation(mongo_db, monkeypatch):
    record = payment("mode")
    monkeypatch.setattr(payment_module.razorpay_gateway, "mode", lambda: "live")
    with pytest.raises(HTTPException) as error:
        run(payment_module.RazorpayPaymentService()._validate_provider_payment(record, provider(record), record["razorpay_order_id"]))
    assert error.value.status_code == 409
