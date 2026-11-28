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

from services.razorpay_payment_service import RazorpayPaymentService, _safe_payment
from services.razorpay_service import RazorpayGateway


def payment_record():
    return {"id": "internal-payment", "amount_paise": 299900, "currency": "INR"}


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
