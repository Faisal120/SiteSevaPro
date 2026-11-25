"""Mongo-backed public endpoint limits shared by every API worker."""
from __future__ import annotations

import hashlib
import os
import time
from datetime import datetime, timedelta, timezone

from fastapi import HTTPException, Request

from core import db


class _PersistentRateLimiter:
    @staticmethod
    def _hash(value: str) -> str:
        secret = os.getenv("AUTH_CHALLENGE_SECRET") or os.getenv("JWT_SECRET", "")
        return hashlib.sha256(f"{secret}:{value}".encode()).hexdigest()

    async def check(self, request: Request, bucket: str, limit: int, window_seconds: int) -> None:
        client = request.client.host if request.client else "unknown"
        await self.check_key(f"{bucket}:ip:{client}", limit, window_seconds)

    async def check_key(self, key: str, limit: int, window_seconds: int) -> None:
        now = time.time()
        stored_key = self._hash(key)
        query = {"key": stored_key, "created_epoch": {"$gte": now - window_seconds}}
        oldest = await db.rate_limit_events.find_one(query, sort=[("created_epoch", 1)])
        if await db.rate_limit_events.count_documents(query) >= limit:
            retry_after = max(1, int(window_seconds - (now - float(oldest.get("created_epoch", now))))) if oldest else window_seconds
            raise HTTPException(429, "Too many requests. Please try again later.", headers={"Retry-After": str(retry_after)})
        await db.rate_limit_events.insert_one({
            "key": stored_key,
            "created_epoch": now,
            "purge_at": datetime.now(timezone.utc) + timedelta(seconds=window_seconds + 60),
        })


_limiter = _PersistentRateLimiter()


def rate_limit(bucket: str, limit: int, window_seconds: int):
    async def dependency(request: Request) -> None:
        await _limiter.check(request, bucket, limit, window_seconds)
    return dependency


async def rate_limit_account(bucket: str, identifier: str, limit: int, window_seconds: int) -> None:
    await _limiter.check_key(f"{bucket}:account:{identifier.strip().lower()}", limit, window_seconds)
