"""Small, server-only wrapper around the official Razorpay Python SDK.

The wrapper deliberately does not provide a browser fallback: an unavailable or
misconfigured gateway must leave a payment pending/not created rather than make
the application appear to have collected money.
"""
from __future__ import annotations

import asyncio
import os
from typing import Any

from fastapi import HTTPException
import requests


class _TimeoutSession(requests.Session):
    """Razorpay SDK session with a hard upper bound for provider calls."""
    def request(self, method, url, **kwargs):
        kwargs.setdefault("timeout", int(os.getenv("RAZORPAY_TIMEOUT_SECONDS", "15")))
        return super().request(method, url, **kwargs)


class RazorpayGateway:
    def _settings(self) -> tuple[str, str, str]:
        key_id = os.getenv("RAZORPAY_KEY_ID", "").strip()
        key_secret = os.getenv("RAZORPAY_KEY_SECRET", "").strip()
        webhook_secret = os.getenv("RAZORPAY_WEBHOOK_SECRET", "").strip()
        if not key_id or not key_secret:
            raise HTTPException(503, "Online payments are not configured")
        return key_id, key_secret, webhook_secret

    def public_key_id(self) -> str:
        return self._settings()[0]

    def mode(self) -> str:
        mode = os.getenv("RAZORPAY_MODE", "test").strip().lower()
        if mode not in {"test", "live"}:
            raise HTTPException(503, "Online payments are not configured")
        return mode

    def _client(self):
        try:
            import razorpay
        except ImportError as error:  # makes an incomplete deploy fail safely
            raise HTTPException(503, "Online payments are not available") from error
        key_id, key_secret, _ = self._settings()
        return razorpay.Client(session=_TimeoutSession(), auth=(key_id, key_secret))

    async def create_order(self, payload: dict[str, Any]) -> dict[str, Any]:
        client = self._client()
        try:
            return await asyncio.to_thread(client.order.create, payload)
        except Exception as error:
            raise HTTPException(502, "Could not create payment order") from error

    async def fetch_payment(self, payment_id: str) -> dict[str, Any]:
        client = self._client()
        for attempt in range(2):
            try:
                return await asyncio.to_thread(client.payment.fetch, payment_id)
            except Exception as error:
                if attempt:
                    raise HTTPException(502, "Could not verify payment with provider") from error

    def verify_payment_signature(self, order_id: str, payment_id: str, signature: str) -> None:
        try:
            client = self._client()
            client.utility.verify_payment_signature({
                "razorpay_order_id": order_id,
                "razorpay_payment_id": payment_id,
                "razorpay_signature": signature,
            })
        except HTTPException:
            raise
        except Exception as error:
            raise HTTPException(400, "Payment signature verification failed") from error

    def verify_webhook_signature(self, body: bytes, signature: str | None) -> None:
        _, _, webhook_secret = self._settings()
        if not webhook_secret or not signature:
            raise HTTPException(401, "Invalid webhook signature")
        try:
            client = self._client()
            client.utility.verify_webhook_signature(body.decode("utf-8"), signature, webhook_secret)
        except HTTPException:
            raise
        except Exception as error:
            raise HTTPException(401, "Invalid webhook signature") from error


razorpay_gateway = RazorpayGateway()
