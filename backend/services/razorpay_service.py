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
    def checkout_rollout(self) -> str:
        """Return the server-side policy for *new* checkout sessions.

        ``PAYMENTS_ENABLED`` remains the master emergency kill switch.  The
        rollout setting only narrows an enabled checkout, never widens a
        disabled one.  Keeping this decision on the server prevents a
        modified React bundle from opening public checkout.
        """
        enabled = os.getenv("PAYMENTS_ENABLED", "").strip().lower()
        if enabled not in {"1", "true", "yes", "on"}:
            return "disabled"
        configured = os.getenv("PAYMENTS_CHECKOUT_ROLLOUT", "").strip().lower()
        # A missing rollout is deliberately fail-closed even if an operator
        # has set PAYMENTS_ENABLED=true. Public collection needs two explicit
        # decisions: enable payments and select the public rollout.
        if not configured:
            return "disabled"
        if configured not in {"disabled", "restricted", "public"}:
            return "disabled"
        return configured

    @staticmethod
    def _allowlisted_user_ids() -> set[str]:
        return {
            value.strip()
            for value in os.getenv("PAYMENTS_CHECKOUT_ALLOWED_USER_IDS", "").split(",")
            if value.strip()
        }

    def checkout_availability(self, user: dict) -> dict[str, str | bool]:
        """Safe authenticated availability response; never includes keys."""
        rollout = self.checkout_rollout()
        if rollout == "disabled":
            return {"status": "DISABLED", "checkout_available": False}
        if rollout == "restricted" and str(user.get("id") or "") not in self._allowlisted_user_ids():
            return {"status": "RESTRICTED", "checkout_available": False}
        try:
            self.validate_checkout_configuration()
        except HTTPException:
            return {"status": "NOT_CONFIGURED", "checkout_available": False}
        return {"status": "AVAILABLE", "checkout_available": True, "rollout": rollout}

    def require_checkout_enabled(self, user: dict) -> None:
        """Authorize a new order only; never use this for recovery flows."""
        availability = self.checkout_availability(user)
        if availability["checkout_available"]:
            return
        if availability["status"] == "RESTRICTED":
            raise HTTPException(403, "Checkout is not enabled for this account")
        if availability["status"] == "NOT_CONFIGURED":
            raise HTTPException(503, "Online payments are not configured")
        raise HTTPException(503, "Online payments are coming soon")

    def validate_checkout_configuration(self) -> str:
        """Validate every secret required before accepting a *new* payment.

        Recovery and signed-webhook verification intentionally use narrower
        checks so an operator can turn off new checkout without abandoning a
        customer whose valid order is already in flight.
        """
        mode = self.mode()
        webhook_secret = self._settings()[2]
        placeholder = ("replace", "change_me", "your_", "example", "placeholder")
        if not webhook_secret or any(marker in webhook_secret.lower() for marker in placeholder):
            raise HTTPException(503, "Online payments are not configured")
        return mode

    def _settings(self) -> tuple[str, str, str]:
        key_id = os.getenv("RAZORPAY_KEY_ID", "").strip()
        key_secret = os.getenv("RAZORPAY_KEY_SECRET", "").strip()
        webhook_secret = os.getenv("RAZORPAY_WEBHOOK_SECRET", "").strip()
        placeholder = ("replace", "change_me", "your_", "example", "placeholder")
        if not key_id or not key_secret or any(marker in key_id.lower() or marker in key_secret.lower() for marker in placeholder):
            raise HTTPException(503, "Online payments are not configured")
        return key_id, key_secret, webhook_secret

    def public_key_id(self) -> str:
        return self._settings()[0]

    def mode(self) -> str:
        mode = os.getenv("RAZORPAY_MODE", "test").strip().lower()
        if mode not in {"test", "live"}:
            raise HTTPException(503, "Online payments are not configured")
        key_id = self._settings()[0]
        if os.getenv("APP_ENV", "development").strip().lower() == "production" and mode != "live":
            raise HTTPException(503, "Live Razorpay credentials are required in production")
        if not key_id.startswith(f"rzp_{mode}_"):
            raise HTTPException(503, "Razorpay key does not match configured gateway mode")
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

    async def fetch_order_payments(self, order_id: str) -> list[dict[str, Any]]:
        """Return provider payments for a stored order without trusting a client.

        This is deliberately a recovery-only primitive: it lets a background
        reconciler recover an order when a customer completed checkout but the
        browser closed before its payment id reached our API.  Razorpay's SDK
        returns an ``items`` envelope for this endpoint, but accepting a list
        keeps the wrapper compatible with supported SDK versions.
        """
        client = self._client()
        for attempt in range(2):
            try:
                result = await asyncio.to_thread(client.order.payments, order_id)
                if isinstance(result, dict):
                    items = result.get("items", [])
                else:
                    items = result
                return [item for item in (items or []) if isinstance(item, dict)]
            except Exception as error:
                if attempt:
                    raise HTTPException(502, "Could not reconcile payment order with provider") from error

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
