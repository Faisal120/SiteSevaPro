import asyncio
import hashlib
import hmac
import os

import pytest
from fastapi import HTTPException

# Keep imports local and isolated from any developer/production environment.
os.environ.setdefault("MONGO_URL", "mongodb://127.0.0.1:27017")
os.environ.setdefault("DB_NAME", "siteseva_razorpay_test")
os.environ.setdefault("JWT_SECRET", "test-jwt-secret")
os.environ.setdefault("SUPER_ADMIN_EMAIL", "admin@example.test")
os.environ.setdefault("SUPER_ADMIN_PASSWORD", "not-a-production-password")
os.environ.setdefault("RAZORPAY_KEY_ID", "rzp_test_key")
os.environ.setdefault("RAZORPAY_KEY_SECRET", "test-secret")

from services.razorpay_payment_service import RazorpayPaymentService, _safe_payment
from services.razorpay_service import RazorpayGateway
from api.design_wallet import request_purchase
from v2 import retired_manual_payment_request


def payment_record():
    return {"id": "internal-payment", "amount_paise": 299900, "currency": "INR", "razorpay_mode": "test"}


def provider_payment(**overrides):
    payment = {"id": "pay_test_1", "order_id": "order_test_1", "amount": 299900, "currency": "INR", "status": "captured"}
    payment.update(overrides)
    return payment


def test_provider_payment_requires_original_order_amount_currency_and_capture():
    service = RazorpayPaymentService()
    asyncio.run(service._validate_provider_payment(payment_record(), provider_payment(), "order_test_1"))
    for changed in ({"order_id": "order_other"}, {"amount": 1}, {"currency": "USD"}, {"status": "authorized"}):
        with pytest.raises(HTTPException):
            asyncio.run(service._validate_provider_payment(payment_record(), provider_payment(**changed), "order_test_1"))


def test_paid_checkout_is_disabled_by_default_before_any_database_write(monkeypatch):
    monkeypatch.delenv("PAYMENTS_ENABLED", raising=False)
    with pytest.raises(HTTPException) as error:
        asyncio.run(RazorpayPaymentService().create_order("PREMIUM", {"id": "u1", "company_id": "c1"}))
    assert error.value.status_code == 503
    assert error.value.detail == "Online payments are coming soon"


def test_disabled_mode_blocks_browser_verification_and_webhook_fulfilment(monkeypatch):
    monkeypatch.setenv("PAYMENTS_ENABLED", "false")
    service = RazorpayPaymentService()
    blocked_calls = (
        service.verify_browser_payment("order_test_1", "pay_test_1", "signature", {"id": "u1", "company_id": "c1"}),
        service.handle_webhook("payment.captured", "event-1", {}),
    )
    for call in blocked_calls:
        with pytest.raises(HTTPException) as error:
            asyncio.run(call)
        assert error.value.status_code == 503
        assert error.value.detail == "Online payments are coming soon"


def test_production_rejects_test_razorpay_keys(monkeypatch):
    monkeypatch.setenv("APP_ENV", "production")
    monkeypatch.setenv("RAZORPAY_MODE", "test")
    monkeypatch.setenv("RAZORPAY_KEY_ID", "rzp_test_key")
    monkeypatch.setenv("RAZORPAY_KEY_SECRET", "test-secret")
    with pytest.raises(HTTPException) as error:
        RazorpayGateway().mode()
    assert error.value.status_code == 503
    assert error.value.detail == "Live Razorpay credentials are required in production"


def test_enabled_production_checkout_fails_safely_without_live_credentials(monkeypatch):
    monkeypatch.setenv("APP_ENV", "production")
    monkeypatch.setenv("PAYMENTS_ENABLED", "true")
    monkeypatch.setenv("RAZORPAY_MODE", "live")
    monkeypatch.delenv("RAZORPAY_KEY_ID", raising=False)
    monkeypatch.delenv("RAZORPAY_KEY_SECRET", raising=False)
    with pytest.raises(HTTPException) as error:
        RazorpayGateway().mode()
    assert error.value.status_code == 503
    assert error.value.detail == "Online payments are not configured"


def test_legacy_manual_payment_and_credit_purchase_endpoints_stay_retired():
    for endpoint in (request_purchase, retired_manual_payment_request):
        with pytest.raises(HTTPException) as error:
            asyncio.run(endpoint({}))
        assert error.value.status_code == 410


def test_safe_payment_payload_never_contains_provider_signature_or_raw_data():
    public = _safe_payment({"id": "p1", "status": "CAPTURED", "amount": 2999, "provider_signature": "secret", "provider_payload": {"sensitive": True}, "notes": {"email": "private"}})
    assert public == {"id": "p1", "status": "CAPTURED", "amount": 2999}


def test_webhook_rejects_missing_signature(monkeypatch):
    monkeypatch.setenv("RAZORPAY_KEY_ID", "rzp_test_key")
    monkeypatch.setenv("RAZORPAY_KEY_SECRET", "test-secret")
    monkeypatch.setenv("RAZORPAY_WEBHOOK_SECRET", "webhook-secret")
    with pytest.raises(HTTPException) as error:
        RazorpayGateway().verify_webhook_signature(b"{}", None)
    assert error.value.status_code == 401


def test_webhook_accepts_only_a_signature_for_the_exact_raw_body(monkeypatch):
    monkeypatch.setenv("RAZORPAY_KEY_ID", "rzp_test_key")
    monkeypatch.setenv("RAZORPAY_KEY_SECRET", "test-secret")
    monkeypatch.setenv("RAZORPAY_WEBHOOK_SECRET", "webhook-secret")
    body = b'{"event":"payment.captured"}'
    signature = hmac.new(b"webhook-secret", body, hashlib.sha256).hexdigest()
    RazorpayGateway().verify_webhook_signature(body, signature)
    with pytest.raises(HTTPException):
        RazorpayGateway().verify_webhook_signature(body + b" ", signature)


def test_browser_signature_verification_delegates_to_official_sdk(monkeypatch):
    monkeypatch.setenv("RAZORPAY_KEY_ID", "rzp_test_key")
    monkeypatch.setenv("RAZORPAY_KEY_SECRET", "test-secret")

    class Utility:
        def __init__(self): self.payload = None
        def verify_payment_signature(self, payload): self.payload = payload
    class Client: utility = Utility()
    client = Client()
    gateway = RazorpayGateway()
    monkeypatch.setattr(gateway, "_client", lambda: client)
    gateway.verify_payment_signature("order_test_1", "pay_test_1", "signature")
    assert client.utility.payload["razorpay_order_id"] == "order_test_1"
    assert client.utility.payload["razorpay_payment_id"] == "pay_test_1"
