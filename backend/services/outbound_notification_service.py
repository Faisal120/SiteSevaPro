"""Optional outbound notifications for approval events.

No credential means no external message is attempted; the in-app notification is
always the reliable fallback. Configure SMTP_* and/or WHATSAPP_* environment
variables in production to activate delivery.
"""
import asyncio
import json
import os
import smtplib
from email.message import EmailMessage
from urllib.request import Request, urlopen

from core import db, now_iso


async def notify_credit_approval(user_id: str, credits: int) -> None:
    user = await db.users.find_one({"id": user_id}, {"_id": 0}) or {}
    text = f"Your SiteSeva Pro Design Studio wallet has been credited with {credits} credits."
    deliveries = []
    if user.get("email") and os.getenv("SMTP_HOST") and os.getenv("SMTP_FROM"):
        try:
            await asyncio.to_thread(_send_email, user["email"], "Design credits approved", text)
            deliveries.append("EMAIL_SENT")
        except Exception as error:
            deliveries.append(f"EMAIL_FAILED:{error}")
    phone = user.get("phone") or user.get("whatsapp")
    if phone and os.getenv("WHATSAPP_API_URL") and os.getenv("WHATSAPP_API_TOKEN"):
        try:
            await asyncio.to_thread(_send_whatsapp, phone, text)
            deliveries.append("WHATSAPP_SENT")
        except Exception as error:
            deliveries.append(f"WHATSAPP_FAILED:{error}")
    await db.outbound_notifications.insert_one({"user_id": user_id, "event": "DESIGN_CREDITS_APPROVED", "deliveries": deliveries or ["IN_APP_ONLY"], "created_at": now_iso()})


def _send_email(to_address: str, subject: str, body: str) -> None:
    message = EmailMessage()
    message["From"] = os.environ["SMTP_FROM"]
    message["To"] = to_address
    message["Subject"] = subject
    message.set_content(body)
    with smtplib.SMTP(os.environ["SMTP_HOST"], int(os.getenv("SMTP_PORT", "587")), timeout=12) as server:
        if os.getenv("SMTP_TLS", "true").lower() == "true": server.starttls()
        if os.getenv("SMTP_USERNAME"): server.login(os.environ["SMTP_USERNAME"], os.getenv("SMTP_PASSWORD", ""))
        server.send_message(message)


def _send_whatsapp(phone: str, text: str) -> None:
    payload = json.dumps({"to": phone, "type": "text", "text": {"body": text}}).encode()
    request = Request(os.environ["WHATSAPP_API_URL"], data=payload, method="POST", headers={"Authorization": f"Bearer {os.environ['WHATSAPP_API_TOKEN']}", "Content-Type": "application/json"})
    with urlopen(request, timeout=12): pass
