"""Realtime and Firebase delivery for persisted SiteSeva notifications."""
from __future__ import annotations

import asyncio
import json
import logging
import os
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from fastapi import WebSocket

from core import db

logger = logging.getLogger("siteseva.notifications")


@dataclass(eq=False)
class _RealtimeConnection:
    websocket: WebSocket
    user_id: str
    company_id: str | None


class NotificationRealtimeHub:
    def __init__(self) -> None:
        self._connections: set[_RealtimeConnection] = set()
        self._lock = asyncio.Lock()

    async def connect(self, websocket: WebSocket, user: dict) -> None:
        await websocket.accept()
        connection = _RealtimeConnection(
            websocket=websocket,
            user_id=user["id"],
            company_id=user.get("company_id"),
        )
        websocket.state.notification_connection = connection
        async with self._lock:
            self._connections.add(connection)

    async def disconnect(self, websocket: WebSocket) -> None:
        connection = getattr(websocket.state, "notification_connection", None)
        if connection is None:
            return
        async with self._lock:
            self._connections.discard(connection)

    async def publish(self, notification: dict) -> None:
        async with self._lock:
            connections = list(self._connections)
        recipients = [
            connection
            for connection in connections
            if self._can_receive(connection, notification)
        ]
        if not recipients:
            return
        payload = {"event": "notification.created", "data": notification}
        results = await asyncio.gather(
            *(connection.websocket.send_json(payload) for connection in recipients),
            return_exceptions=True,
        )
        for connection, result in zip(recipients, results):
            if isinstance(result, Exception):
                async with self._lock:
                    self._connections.discard(connection)

    @staticmethod
    def _can_receive(
        connection: _RealtimeConnection,
        notification: dict,
    ) -> bool:
        target_user = notification.get("user_id")
        target_company = notification.get("company_id")
        if target_user:
            return connection.user_id == target_user
        return target_company is not None and connection.company_id == target_company


class FirebasePushDelivery:
    def __init__(self) -> None:
        self._checked = False
        self._messaging: Any | None = None

    def _initialize(self) -> bool:
        if self._checked:
            return self._messaging is not None
        self._checked = True
        try:
            import firebase_admin
            from firebase_admin import credentials, messaging

            try:
                firebase_admin.get_app()
            except ValueError:
                inline = os.getenv("FIREBASE_SERVICE_ACCOUNT_JSON", "").strip()
                credentials_path = os.getenv(
                    "GOOGLE_APPLICATION_CREDENTIALS",
                    "",
                ).strip()
                if inline:
                    firebase_admin.initialize_app(
                        credentials.Certificate(json.loads(inline))
                    )
                elif credentials_path and Path(credentials_path).is_file():
                    firebase_admin.initialize_app(
                        credentials.Certificate(credentials_path)
                    )
                else:
                    logger.info(
                        "Firebase push disabled: service account is not configured"
                    )
                    return False
            self._messaging = messaging
            return True
        except (ImportError, ValueError, json.JSONDecodeError):
            logger.exception("Firebase push initialization failed")
            return False

    async def send(self, notification: dict) -> None:
        if not self._initialize():
            return
        query: dict[str, Any] = {"enabled": {"$ne": False}}
        if notification.get("user_id"):
            query["user_id"] = notification["user_id"]
        elif notification.get("company_id"):
            query["company_id"] = notification["company_id"]
        else:
            return
        devices = await db.push_devices.find(
            query,
            {"_id": 0, "token": 1},
        ).to_list(5000)
        tokens = list({item.get("token") for item in devices if item.get("token")})
        for offset in range(0, len(tokens), 500):
            await self._send_batch(tokens[offset : offset + 500], notification)

    async def _send_batch(self, tokens: list[str], notification: dict) -> None:
        if not tokens or self._messaging is None:
            return
        messaging = self._messaging
        data = {
            key: str(value)
            for key, value in {
                "notification_id": notification.get("id"),
                "type": notification.get("type"),
                "priority": notification.get("priority"),
                "site_id": notification.get("site_id"),
                "action_url": notification.get("action_url"),
            }.items()
            if value is not None
        }
        message = messaging.MulticastMessage(
            tokens=tokens,
            notification=messaging.Notification(
                title=notification.get("title") or "SiteSeva Pro",
                body=notification.get("message") or "Project update available",
            ),
            data=data,
            android=messaging.AndroidConfig(priority="high"),
        )
        try:
            sender = getattr(
                messaging,
                "send_each_for_multicast",
                getattr(messaging, "send_multicast", None),
            )
            if sender is None:
                return
            response = await asyncio.to_thread(sender, message)
            invalid_tokens = []
            for token, item in zip(tokens, response.responses):
                if item.success:
                    continue
                reason = str(item.exception).lower()
                if "not-registered" in reason or "registration-token-not-registered" in reason:
                    invalid_tokens.append(token)
            if invalid_tokens:
                await db.push_devices.update_many(
                    {"token": {"$in": invalid_tokens}},
                    {"$set": {"enabled": False}},
                )
        except Exception:
            logger.exception("Firebase notification delivery failed")


class NotificationDelivery:
    def __init__(self) -> None:
        self.realtime = NotificationRealtimeHub()
        self.push = FirebasePushDelivery()

    async def deliver(self, notification: dict) -> None:
        try:
            await self.realtime.publish(notification)
            await self.push.send(notification)
        except Exception:
            logger.exception("Notification delivery failed after persistence")


notification_delivery = NotificationDelivery()
