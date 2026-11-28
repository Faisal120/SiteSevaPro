"""Mongo-backed public endpoint limits shared by every API worker."""
from __future__ import annotations

import hashlib
import os
import time
from datetime import datetime, timedelta, timezone

from fastapi import HTTPException, Request
from pymongo import ReturnDocument
from pymongo.errors import DuplicateKeyError

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
        # A single MongoDB counter avoids the count-then-insert race that let
        # simultaneous requests exceed a limit across multiple API workers.
        window_start = int(now // window_seconds) * window_seconds
        query = {"key": stored_key, "window_start": window_start}
        update = {
            "$inc": {"count": 1},
            "$setOnInsert": {
                "key": stored_key,
                "window_start": window_start,
                "created_epoch": now,
                "purge_at": datetime.now(timezone.utc) + timedelta(seconds=window_seconds + 60),
            },
        }
        try:
            bucket = await db.rate_limit_buckets.find_one_and_update(
                query,
                update,
                upsert=True,
                return_document=ReturnDocument.AFTER,
            )
        except DuplicateKeyError:
            # The unique index can race only while a new bucket is created.
            # Retrying against the now-created document remains atomic.
            bucket = await db.rate_limit_buckets.find_one_and_update(
                query,
                {"$inc": {"count": 1}},
                return_document=ReturnDocument.AFTER,
            )
        if not bucket or int(bucket.get("count", 0)) > limit:
            retry_after = max(1, int(window_start + window_seconds - now))
            raise HTTPException(
                429,
                "Too many requests. Please try again later.",
                headers={"Retry-After": str(retry_after)},
            )


_limiter = _PersistentRateLimiter()


def rate_limit(bucket: str, limit: int, window_seconds: int):
    async def dependency(request: Request) -> None:
        await _limiter.check(request, bucket, limit, window_seconds)
    return dependency


async def rate_limit_account(bucket: str, identifier: str, limit: int, window_seconds: int) -> None:
    await _limiter.check_key(f"{bucket}:account:{identifier.strip().lower()}", limit, window_seconds)
