"""Reliable outbound account and approval notifications.

WhatsApp messages are sent through Meta's Cloud API using approved templates.
Every attempt is persisted so the admin panel can show whether Meta accepted,
rejected, or could not send the notification.
"""
from __future__ import annotations

import asyncio
import json
import logging
import os
import smtplib
from email.message import EmailMessage
from typing import Any

import requests

from core import db, new_id, now_iso
from services.account_security import mask_phone, normalize_phone
from services.whatsapp_templates import authentication_components


logger = logging.getLogger("siteseva.outbound")


def _template_parameters(values: list[str]) -> list[dict[str, str]]:
    return [{"type": "text", "text": str(value)} for value in values]


def _public_delivery(delivery: dict) -> dict:
    return {
        "id": delivery["id"],
        "channel": delivery["channel"],
        "event": delivery["event"],
        "status": delivery["status"],
        "recipient": mask_phone(delivery.get("to", "")),
        "provider_message_id": delivery.get("provider_message_id"),
        "error": delivery.get("last_error"),
        "created_at": delivery["created_at"],
    }


class OutboundNotificationService:
    def _config(self) -> tuple[str, str, str]:
        return (
            os.getenv("WHATSAPP_ACCESS_TOKEN", "").strip()
            or os.getenv("WHATSAPP_API_TOKEN", "").strip(),
            os.getenv("WHATSAPP_PHONE_NUMBER_ID", "").strip(),
            os.getenv("WHATSAPP_API_VERSION", "v27.0").strip(),
        )

    async def send_template(
        self,
        *,
        event: str,
        phone: str,
        template_name: str,
        values: list[str],
        user_id: str | None = None,
        company_id: str | None = None,
        language: str | None = None,
        components: list[dict[str, Any]] | None = None,
        dedupe_key: str | None = None,
    ) -> dict:
        try:
            normalized = normalize_phone(phone)
        except ValueError as error:
            delivery = {
                "id": new_id(),
                "channel": "WHATSAPP",
                "event": event,
                "user_id": user_id,
                "company_id": company_id,
                "to": str(phone or ""),
                "template_name": template_name,
                "status": "INVALID_PHONE",
                "attempts": 0,
                "last_error": str(error),
                "created_at": now_iso(),
                "updated_at": now_iso(),
            }
            await db.outbound_notifications.insert_one(dict(delivery))
            return _public_delivery(delivery)
        if dedupe_key:
            existing = await db.outbound_notifications.find_one(
                {"dedupe_key": dedupe_key, "status": {"$in": ["PENDING", "ACCEPTED", "SENT", "DELIVERED", "READ"]}},
                {"_id": 0},
            )
            if existing:
                return _public_delivery(existing)
        delivery = {
            "id": new_id(),
            "channel": "WHATSAPP",
            "event": event,
            "user_id": user_id,
            "company_id": company_id,
            "to": normalized,
            "template_name": template_name,
            "status": "PENDING",
            "attempts": 0,
            "created_at": now_iso(),
            "updated_at": now_iso(),
        }
        if dedupe_key:
            delivery["dedupe_key"] = dedupe_key
        await db.outbound_notifications.insert_one(dict(delivery))

        token, phone_number_id, version = self._config()
        if not token or not phone_number_id:
            delivery["status"] = "NOT_CONFIGURED"
            delivery["last_error"] = "WhatsApp Cloud API is not configured"
            await self._save_result(delivery)
            return _public_delivery(delivery)

        payload: dict[str, Any] = {
            "messaging_product": "whatsapp",
            "recipient_type": "individual",
            "to": normalized.lstrip("+"),
            "type": "template",
            "template": {
                "name": template_name,
                "language": {
                    "code": language
                    or os.getenv("WHATSAPP_TEMPLATE_LANGUAGE", "en")
                },
            },
        }
        if components:
            payload["template"]["components"] = components
        elif values:
            payload["template"]["components"] = [
                {
                    "type": "body",
                    "parameters": _template_parameters(values),
                }
            ]

        url = f"https://graph.facebook.com/{version}/{phone_number_id}/messages"
        for attempt in range(1, 4):
            delivery["attempts"] = attempt
            try:
                response = await asyncio.to_thread(requests.post, url, headers={"Authorization": f"Bearer {token}", "Content-Type": "application/json"}, json=payload, timeout=20)
                body = response.json() if response.content else {}
                if response.ok:
                    delivery["status"] = "ACCEPTED"
                    delivery["provider_message_id"] = (body.get("messages") or [{}])[0].get("id")
                    delivery["accepted_at"] = now_iso()
                    break
                # Meta error bodies can contain provider-side diagnostics. They
                # are not needed by the app and must not be retained or exposed.
                message = "WhatsApp provider rejected the template request"
                if response.status_code not in {429, 500, 502, 503, 504} or attempt == 3:
                    delivery["status"] = "RATE_LIMITED" if response.status_code == 429 else "FAILED"
                    delivery["last_error"] = message
                    break
            except (requests.Timeout, requests.ConnectionError) as error:
                if attempt == 3:
                    delivery["status"] = "FAILED"
                    delivery["last_error"] = type(error).__name__
                    logger.warning("WhatsApp template delivery failed for %s", event)
                    break
            except Exception as error:
                delivery["status"] = "FAILED"
                delivery["last_error"] = "WhatsApp provider request failed"
                logger.warning("WhatsApp template delivery failed for %s (%s)", event, type(error).__name__)
                break
            await asyncio.sleep(0.4 * attempt)
        await self._save_result(delivery)
        return _public_delivery(delivery)

    async def _save_result(self, delivery: dict) -> None:
        delivery["updated_at"] = now_iso()
        await db.outbound_notifications.update_one(
            {"id": delivery["id"]},
            {"$set": {key: value for key, value in delivery.items() if key != "_id"}},
        )

    async def send_credentials(
        self,
        user: dict,
        temporary_password: str | None = None,
    ) -> dict:
        # Kept only so un-upgraded callers cannot send a plaintext password.
        # The password argument is intentionally ignored.
        return await self.send_account_approved(user)

    async def send_account_approved(self, user: dict, *, dedupe_key: str | None = None) -> dict:
        phone = user.get("whatsapp") or user.get("phone")
        if not phone:
            return {
                "channel": "WHATSAPP",
                "event": "ACCOUNT_APPROVED",
                "status": "NO_PHONE",
                "error": "No WhatsApp number is stored for this account",
            }
        try:
            return await self.send_template(
                event="ACCOUNT_APPROVED",
                phone=phone,
                template_name=os.getenv(
                    "WHATSAPP_ACCOUNT_APPROVED_TEMPLATE",
                    "siteseva_account_approved",
                ),
                values=[
                    user.get("full_name") or "SiteSeva user",
                    user.get("company_name") or "SiteSeva Pro",
                    user.get("username") or user.get("email", ""),
                ],
                user_id=user.get("id"),
                company_id=user.get("company_id"),
                language=os.getenv("WHATSAPP_ACCOUNT_APPROVED_TEMPLATE_LANGUAGE") or None,
                dedupe_key=dedupe_key,
            )
        except Exception as error:
            logger.warning("Account approval notification failed (%s)", type(error).__name__)
            return {"channel": "WHATSAPP", "event": "ACCOUNT_CREDENTIALS", "status": "FAILED", "error": "Notification request failed"}

    async def send_activation_otp(self, user: dict, code: str, challenge_id: str) -> dict:
        return await self._send_authentication_otp(user, code, challenge_id, "ACTIVATION")

    async def send_password_reset(self, user: dict, code: str, challenge_id: str | None = None) -> dict:
        return await self._send_authentication_otp(user, code, challenge_id or new_id(), "PASSWORD_RESET")

    async def _send_authentication_otp(self, user: dict, code: str, challenge_id: str, purpose: str) -> dict:
        phone = user.get("whatsapp") or user.get("phone")
        if not phone:
            return {
                "channel": "WHATSAPP",
                "event": f"{purpose}_OTP",
                "status": "NO_PHONE",
                "error": "No WhatsApp number is stored for this account",
            }
        try:
            return await self.send_template(
                event=f"{purpose}_OTP",
                phone=phone,
                template_name=os.getenv(
                    "WHATSAPP_CREDENTIALS_TEMPLATE" if purpose == "ACTIVATION" else "WHATSAPP_PASSWORD_RESET_TEMPLATE",
                    "siteseva_account_credentials" if purpose == "ACTIVATION" else "siteseva_password_reset",
                ),
                values=[code],
                user_id=user.get("id"),
                company_id=user.get("company_id"),
                language=(os.getenv("WHATSAPP_ACTIVATION_TEMPLATE_LANGUAGE") if purpose == "ACTIVATION" else os.getenv("WHATSAPP_PASSWORD_RESET_TEMPLATE_LANGUAGE")) or None,
                components=authentication_components(code, os.getenv("WHATSAPP_AUTH_OTP_BUTTON_INDEX", "0")),
                dedupe_key=f"{purpose}:{challenge_id}",
            )
        except Exception as error:
            logger.warning("Authentication notification failed (%s)", type(error).__name__)
            return {"channel": "WHATSAPP", "event": f"{purpose}_OTP", "status": "FAILED", "error": "Notification request failed"}

    async def send_application_status(self, application: dict, status: str, details: str) -> dict:
        """Template D is reserved strictly for registration status events."""
        return await self.send_template(
            event="APPLICATION_STATUS",
            phone=application.get("mobile", ""),
            template_name=os.getenv("WHATSAPP_APPROVAL_TEMPLATE", "siteseva_approval_update"),
            values=[application.get("owner_name") or "SiteSeva user", status, details],
            language=os.getenv("WHATSAPP_APPROVAL_TEMPLATE_LANGUAGE") or None,
        )

    async def send_approval(
        self,
        user: dict,
        title: str,
        detail: str,
        *,
        event: str = "APPROVAL_UPDATE",
    ) -> dict:
        phone = user.get("whatsapp") or user.get("phone")
        if not phone:
            return {
                "channel": "WHATSAPP",
                "event": event,
                "status": "NO_PHONE",
                "error": "No WhatsApp number is stored for this account",
            }
        try:
            return await self.send_template(
                event=event,
                phone=phone,
                template_name=os.getenv(
                    "WHATSAPP_APPROVAL_TEMPLATE",
                    "siteseva_approval_update",
                ),
                values=[user.get("full_name") or "SiteSeva user", title, detail],
                user_id=user.get("id"),
                company_id=user.get("company_id"),
            )
        except Exception as error:
            logger.warning("Approval notification failed (%s)", type(error).__name__)
            return {"channel": "WHATSAPP", "event": event, "status": "FAILED", "error": "Notification request failed"}

    async def notify_company_approval(
        self,
        company_id: str,
        title: str,
        detail: str,
        *,
        event: str = "APPROVAL_UPDATE",
    ) -> list[dict]:
        users = await db.users.find(
            {
                "company_id": company_id,
                "role": "CONTRACTOR",
                "blocked": {"$ne": True},
            },
            {"_id": 0},
        ).to_list(20)
        return [
            await self.send_approval(user, title, detail, event=event)
            for user in users
        ]

    async def update_provider_status(
        self,
        provider_message_id: str,
        status: str,
        timestamp: str | None = None,
        error: str | None = None,
    ) -> None:
        normalised = status.upper()
        current = await db.outbound_notifications.find_one({"provider_message_id": provider_message_id}, {"_id": 0, "status": 1})
        ranks = {"PENDING": 0, "ACCEPTED": 1, "SENT": 2, "DELIVERED": 3, "READ": 4}
        if current and ranks.get(normalised, -1) < ranks.get(current.get("status", ""), -1):
            return
        patch = {
            "status": normalised,
            "provider_updated_at": timestamp or now_iso(),
            "updated_at": now_iso(),
        }
        if error:
            patch["last_error"] = error[:500]
        await db.outbound_notifications.update_one(
            {"provider_message_id": provider_message_id},
            {"$set": patch},
        )


outbound_notification_service = OutboundNotificationService()


async def notify_credit_approval(user_id: str, credits: int) -> dict:
    """Backward-compatible entry point used by the design wallet router."""

    user = await db.users.find_one({"id": user_id}, {"_id": 0}) or {}
    return await outbound_notification_service.send_approval(
        user,
        "Design credits approved",
        f"{credits} credits were added to your Design Studio wallet.",
        event="DESIGN_CREDITS_APPROVED",
    )


def _send_email(to_address: str, subject: str, body: str) -> None:
    """Kept as an optional operational fallback for future admin tooling."""

    message = EmailMessage()
    message["From"] = os.environ["SMTP_FROM"]
    message["To"] = to_address
    message["Subject"] = subject
    message.set_content(body)
    with smtplib.SMTP(
        os.environ["SMTP_HOST"],
        int(os.getenv("SMTP_PORT", "587")),
        timeout=12,
    ) as server:
        if os.getenv("SMTP_TLS", "true").lower() == "true":
            server.starttls()
        if os.getenv("SMTP_USERNAME"):
            server.login(
                os.environ["SMTP_USERNAME"],
                os.getenv("SMTP_PASSWORD", ""),
            )
        server.send_message(message)
