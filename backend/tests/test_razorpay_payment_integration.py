"""Real-Mongo integration tests for payment fulfilment durability.

Set MONGO_INTEGRATION_URL to an isolated disposable MongoDB database server to
run these tests. The suite fails closed when it is absent so it cannot quietly
turn a required real-database check into a skipped test.
"""
from __future__ import annotations

import asyncio
import os
import uuid
from datetime import datetime, timedelta, timezone

import pytest
from fastapi import HTTPException
from motor.motor_asyncio import AsyncIOMotorClient

os.environ.setdefault("MONGO_URL", "mongodb://127.0.0.1:27018")
os.environ.setdefault("DB_NAME", "sitesevapro_razorpay_test")
os.environ.setdefault("JWT_SECRET", "test-jwt-secret")
os.environ.setdefault("SUPER_ADMIN_EMAIL", "admin@example.test")
os.environ.setdefault("SUPER_ADMIN_PASSWORD", "not-a-production-password")

from services import razorpay_payment_service as payment_module
from services.plan_catalog import plan_details


def run(loop: asyncio.AbstractEventLoop, awaitable):
    """Run every integration coroutine on the Motor client's dedicated loop."""
    return loop.run_until_complete(awaitable)


@pytest.fixture
def mongo_event_loop():
    """A fresh registered loop, unaffected by other tests' ``asyncio.run`` calls."""
    loop = asyncio.new_event_loop()
    asyncio.set_event_loop(loop)
    try:
        yield loop
    finally:
        # Keep the loop registered until all dependent fixture teardown has
        # completed; pytest tears down mongo_db before this fixture.
        asyncio.set_event_loop(None)
        loop.close()


def integration_url() -> str:
    url = os.getenv("MONGO_INTEGRATION_URL", "").strip()
    if not url:
        pytest.fail(
            "MONGO_INTEGRATION_URL is required and must reference an isolated MongoDB instance",
            pytrace=False,
        )
    return url


@pytest.fixture
def mongo_db(monkeypatch, mongo_event_loop):
    # Motor 3/Python 3.12 no longer obtains a fallback event loop in the main
    # thread. Create/register ours first and bind this client to it explicitly.
    client = AsyncIOMotorClient(
        integration_url(),
        io_loop=mongo_event_loop,
        serverSelectionTimeoutMS=3000,
    )
    database = client[f"siteseva_payment_it_{uuid.uuid4().hex}"]
    database_ready = False
    try:
        run(mongo_event_loop, client.admin.command("ping"))
        database_ready = True
        run(mongo_event_loop, database.subscription_payments.create_index("id", unique=True))
        run(mongo_event_loop, database.subscription_payments.create_index("razorpay_order_id", unique=True, sparse=True))
        run(mongo_event_loop, database.subscription_payments.create_index("razorpay_payment_id", unique=True, sparse=True))
        run(mongo_event_loop, database.subscription_fulfilment_locks.create_index("company_id", unique=True))
        run(mongo_event_loop, database.subscription_credit_grants.create_index("payment_id", unique=True))
        run(mongo_event_loop, database.design_transactions.create_index("subscription_payment_id", unique=True, sparse=True))
        run(mongo_event_loop, database.notifications.create_index("dedupe_key", unique=True, sparse=True))
        run(mongo_event_loop, database.razorpay_webhook_events.create_index("event_id", unique=True))
        run(mongo_event_loop, database.razorpay_refunds.create_index("razorpay_refund_id", unique=True))

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
        yield database
    finally:
        if database_ready:
            run(mongo_event_loop, client.drop_database(database.name))
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


def test_concurrent_browser_and_webhook_fulfil_once(mongo_db, mongo_event_loop, monkeypatch):
    async def scenario():
        record = payment("concurrent")
        await mongo_db.subscription_payments.insert_one(record)
        service = payment_module.RazorpayPaymentService()
        async def fetch(_payment_id):
            return provider(record)
        monkeypatch.setattr(payment_module.razorpay_gateway, "fetch_payment", fetch)
        monkeypatch.setattr(payment_module.razorpay_gateway, "verify_payment_signature", lambda *_args: None)
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
    run(mongo_event_loop, scenario())


def test_duplicate_event_and_failed_retry_are_recoverable(mongo_db, mongo_event_loop, monkeypatch):
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
    run(mongo_event_loop, scenario())


def test_interrupted_credit_grant_and_failed_payment_recover(mongo_db, mongo_event_loop):
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
    run(mongo_event_loop, scenario())


def test_concurrent_renewals_preserve_both_months(mongo_db, mongo_event_loop):
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
    run(mongo_event_loop, scenario())


def test_test_live_mode_isolation(mongo_db, mongo_event_loop, monkeypatch):
    record = payment("mode")
    monkeypatch.setattr(payment_module.razorpay_gateway, "mode", lambda: "live")
    with pytest.raises(HTTPException) as error:
        run(mongo_event_loop, payment_module.RazorpayPaymentService()._validate_provider_payment(record, provider(record), record["razorpay_order_id"]))
    assert error.value.status_code == 409


def test_duplicate_and_out_of_order_refunds_are_recorded_once(mongo_db, mongo_event_loop):
    async def scenario():
        record = payment("refund", status="PENDING")
        record["razorpay_payment_id"] = "pay_refund"
        await mongo_db.subscription_payments.insert_one(record)
        service = payment_module.RazorpayPaymentService()
        partial = {"id": "rfnd-partial", "payment_id": "pay_refund", "amount": 100000, "currency": "INR"}

        # A refund before capture remains pending and is applied as part of
        # durable captured-payment fulfilment instead of being dropped.
        await service._record_refund(partial, "test")
        assert (await mongo_db.razorpay_refunds.find_one({"razorpay_refund_id": "rfnd-partial"}))["status"] == "RECEIVED"
        await service._record_and_fulfil(record, provider(record), "WEBHOOK")
        after_partial = await mongo_db.subscription_payments.find_one({"id": record["id"]})
        assert after_partial["refund_amount_paise"] == 100000
        assert after_partial["refund_status"] == "PARTIAL"
        assert after_partial["status"] == "CAPTURED"

        # Different Razorpay webhook event ids may carry the same provider
        # refund. The provider refund id—not the webhook event—is the durable
        # financial dedupe boundary.
        payload = {"payload": {"refund": {"entity": partial}}}
        await service.handle_webhook("refund.processed", "evt-refund-duplicate-a", payload)
        await service.handle_webhook("refund.processed", "evt-refund-duplicate-b", payload)
        assert (await mongo_db.subscription_payments.find_one({"id": record["id"]}))["refund_amount_paise"] == 100000

        full_remainder = {"id": "rfnd-remainder", "payment_id": "pay_refund", "amount": 199900, "currency": "INR"}
        await service._record_refund(full_remainder, "test")
        completed = await mongo_db.subscription_payments.find_one({"id": record["id"]})
        assert completed["refund_amount_paise"] == record["amount_paise"]
        assert completed["refund_status"] == "FULL"
        assert completed["status"] == "REFUND_REVIEW_REQUIRED"
        assert await mongo_db.razorpay_refunds.count_documents({"razorpay_payment_id": "pay_refund"}) == 2
    run(mongo_event_loop, scenario())


def test_refund_crash_after_atomic_total_is_recovered_without_second_increment(mongo_db, mongo_event_loop, monkeypatch):
    async def scenario():
        record = payment("refund-crash", status="CAPTURED")
        record["razorpay_payment_id"] = "pay_refund-crash"
        await mongo_db.subscription_payments.insert_one(record)
        service = payment_module.RazorpayPaymentService()
        refund = {"id": "rfnd-crash", "payment_id": record["razorpay_payment_id"], "amount": 100000, "currency": "INR"}
        original = service._mark_refund_applied
        calls = {"count": 0}

        async def crash_once(*args):
            calls["count"] += 1
            if calls["count"] == 1:
                raise RuntimeError("simulated process crash")
            await original(*args)

        monkeypatch.setattr(service, "_mark_refund_applied", crash_once)
        with pytest.raises(RuntimeError):
            await service._record_refund(refund, "test")
        after_crash = await mongo_db.subscription_payments.find_one({"id": record["id"]})
        assert after_crash["refund_amount_paise"] == 100000
        assert after_crash["refund_count"] == 1
        await mongo_db.razorpay_refunds.update_one(
            {"razorpay_refund_id": refund["id"]},
            {"$set": {"processing_lease_expires_at": datetime.now(timezone.utc) - timedelta(seconds=1)}},
        )
        await service._apply_pending_refunds(after_crash)
        completed = await mongo_db.subscription_payments.find_one({"id": record["id"]})
        refund_row = await mongo_db.razorpay_refunds.find_one({"razorpay_refund_id": refund["id"]})
        assert completed["refund_amount_paise"] == 100000
        assert completed["refund_count"] == 1
        assert completed["applied_refund_ids"] == [refund["id"]]
        assert refund_row["status"] == "APPLIED"
    run(mongo_event_loop, scenario())


def test_concurrent_partial_refunds_and_overflow_are_consistent(mongo_db, mongo_event_loop):
    async def scenario():
        record = payment("refund-concurrent", status="CAPTURED")
        record["razorpay_payment_id"] = "pay_refund-concurrent"
        await mongo_db.subscription_payments.insert_one(record)
        service = payment_module.RazorpayPaymentService()
        first = {"id": "rfnd-concurrent-a", "payment_id": record["razorpay_payment_id"], "amount": 100000, "currency": "INR"}
        second = {"id": "rfnd-concurrent-b", "payment_id": record["razorpay_payment_id"], "amount": 100000, "currency": "INR"}
        await asyncio.gather(service._record_refund(first, "test"), service._record_refund(second, "test"))
        partially_refunded = await mongo_db.subscription_payments.find_one({"id": record["id"]})
        assert partially_refunded["refund_amount_paise"] == 200000
        assert partially_refunded["refund_count"] == 2
        assert set(partially_refunded["applied_refund_ids"]) == {first["id"], second["id"]}

        overflow = {"id": "rfnd-overflow", "payment_id": record["razorpay_payment_id"], "amount": 100000, "currency": "INR"}
        await service._record_refund(overflow, "test")
        final = await mongo_db.subscription_payments.find_one({"id": record["id"]})
        overflow_row = await mongo_db.razorpay_refunds.find_one({"razorpay_refund_id": overflow["id"]})
        assert final["refund_amount_paise"] == 200000
        assert final["refund_amount_paise"] <= final["amount_paise"]
        assert overflow_row["status"] == "REJECTED_OVERFLOW"
    run(mongo_event_loop, scenario())


def test_order_reconciliation_recovers_captured_attempt_without_browser_payment_id(mongo_db, mongo_event_loop, monkeypatch):
    async def scenario():
        record = payment("order-only", status="PENDING")
        await mongo_db.subscription_payments.insert_one(record)
        service = payment_module.RazorpayPaymentService()
        failed_attempt = {"id": "pay_failed", "order_id": record["razorpay_order_id"], "amount": record["amount_paise"], "currency": "INR", "status": "failed"}
        monkeypatch.setattr(payment_module.razorpay_gateway, "fetch_order_payments", lambda _order: asyncio.sleep(0, result=[failed_attempt, provider(record)]))
        result = await service.status(record["id"], {"company_id": record["company_id"]})
        stored = await mongo_db.subscription_payments.find_one({"id": record["id"]})
        assert result["status"] == "CAPTURED"
        assert stored["razorpay_payment_id"] == "pay_order-only"
        assert stored["status"] == "CAPTURED"
    run(mongo_event_loop, scenario())


def test_reconciliation_is_fair_and_still_works_when_new_checkout_is_disabled(mongo_db, mongo_event_loop, monkeypatch):
    async def scenario():
        first, second = payment("reconcile-a"), payment("reconcile-b")
        await mongo_db.subscription_payments.insert_many([first, second])
        service = payment_module.RazorpayPaymentService()
        monkeypatch.setenv("PAYMENTS_ENABLED", "false")
        monkeypatch.setattr(payment_module.razorpay_gateway, "fetch_order_payments", lambda order: asyncio.sleep(0, result=[provider(first if order == first["razorpay_order_id"] else second)]))
        one = await service.reconcile_pending(limit=1)
        two = await service.reconcile_pending(limit=1)
        assert one["recovered"] == 1
        assert two["recovered"] == 1
        assert await mongo_db.subscription_payments.count_documents({"status": "CAPTURED"}) == 2
    run(mongo_event_loop, scenario())
