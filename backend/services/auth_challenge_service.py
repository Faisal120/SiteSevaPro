"""Persistent, purpose-bound OTP challenges for activation and password reset."""
from __future__ import annotations

import hashlib
import os
import time
from datetime import datetime, timedelta, timezone

import jwt
from fastapi import HTTPException
from pymongo import ReturnDocument

from core import JWT_ALGORITHM, JWT_SECRET, db, hash_password, new_id, now_iso
from repositories.audit_repository import audit_repository
from repositories.user_repository import user_repository
from services.account_security import generate_otp, hash_otp, validate_password_strength, verify_otp
from services.outbound_notification_service import outbound_notification_service
from services.account_status import account_is_denied


ACTIVATION = "ACTIVATION"
PASSWORD_RESET = "PASSWORD_RESET"
_GENERIC_REQUEST = {
    "ok": True,
    "status": "ACCEPTED",
    "message": "If the account is eligible, an OTP will be sent to its registered WhatsApp number.",
}


def _now() -> datetime:
    return datetime.now(timezone.utc)


def _token_hash(token: str) -> str:
    secret = os.getenv("AUTH_CHALLENGE_SECRET") or JWT_SECRET
    return hashlib.sha256(f"{secret}:{token}".encode()).hexdigest()


class AuthChallengeService:
    @staticmethod
    def _settings() -> tuple[int, int, int, int]:
        return (
            int(os.getenv("OTP_EXPIRY_SECONDS", "600")),
            int(os.getenv("OTP_RESEND_COOLDOWN_SECONDS", "60")),
            int(os.getenv("OTP_MAX_ATTEMPTS", "5")),
            int(os.getenv("OTP_MAX_REQUESTS_PER_HOUR", "5")),
        )

    @staticmethod
    def _basic_eligible(user: dict, purpose: str) -> bool:
        if account_is_denied(user):
            return False
        if not (user.get("whatsapp") or user.get("phone")):
            return False
        if purpose == ACTIVATION:
            return bool(user.get("password_setup_required"))
        return bool(user.get("password_hash")) and not user.get("password_setup_required")

    async def _eligible(self, user: dict, purpose: str) -> bool:
        if not self._basic_eligible(user, purpose):
            return False
        if purpose != ACTIVATION or user.get("role") != "CONTRACTOR":
            return True
        # Contractors originate from an approved application. Re-checking the
        # linkage protects migrated legacy records from an accidental flag set.
        application = None
        if user.get("application_id"):
            application = await db.applications.find_one({"id": user["application_id"]}, {"_id": 0, "status": 1})
        if application is None:
            application = await db.applications.find_one({"user_id": user["id"]}, {"_id": 0, "status": 1})
        if application is None and user.get("email"):
            application = await db.applications.find_one({"email": user["email"].lower()}, {"_id": 0, "status": 1})
        return bool(application and str(application.get("status", "")).upper() == "APPROVED")

    async def request(self, identifier: str, purpose: str) -> dict:
        """Issue at most one active challenge. The response never reveals identity state."""
        user = await user_repository.get_by_identifier(identifier)
        if user is None or not await self._eligible(user, purpose):
            return dict(_GENERIC_REQUEST)

        expiry, cooldown, max_attempts, max_requests = self._settings()
        now = _now()
        now_epoch = int(time.time())
        recent = await db.auth_challenges.count_documents(
            {"user_id": user["id"], "purpose": purpose, "created_epoch": {"$gte": now_epoch - 3600}}
        )
        if recent >= max_requests:
            await audit_repository.log("OTP_REQUEST_RATE_LIMITED", "OTP request limit reached", account_id=user["id"], outcome="RATE_LIMITED")
            return {**_GENERIC_REQUEST, "status": "RATE_LIMITED"}
        latest = await db.auth_challenges.find_one(
            {"user_id": user["id"], "purpose": purpose}, sort=[("created_epoch", -1)]
        )
        if latest and latest.get("created_epoch", 0) > now_epoch - cooldown:
            return {**_GENERIC_REQUEST, "status": "RATE_LIMITED"}

        challenge_id = new_id()
        code = generate_otp()
        challenge = {
            "id": challenge_id,
            "challenge_identifier": challenge_id,
            "user_id": user["id"],
            "purpose": purpose,
            "otp_hash": hash_otp(code, purpose=purpose, user_id=user["id"], challenge_id=challenge_id),
            "status": "PENDING",
            "attempts": 0,
            "max_attempts": max_attempts,
            "created_epoch": now_epoch,
            "created_at": now_iso(),
            "expires_at": now + timedelta(seconds=expiry),
            "expires_epoch": now_epoch + expiry,
            "purge_at": now + timedelta(days=1),
        }
        # Superseding before insertion keeps one usable challenge per purpose.
        await db.auth_challenges.update_many(
            {"user_id": user["id"], "purpose": purpose, "status": "PENDING"},
            {"$set": {"status": "SUPERSEDED", "updated_at": now_iso()}},
        )
        await db.auth_challenges.insert_one(challenge)
        if purpose == ACTIVATION:
            delivery = await outbound_notification_service.send_activation_otp(user, code, challenge_id)
        else:
            delivery = await outbound_notification_service.send_password_reset(user, code, challenge_id)
        await db.auth_challenges.update_one(
            {"id": challenge_id},
            {"$set": {"delivery_status": delivery.get("status", "FAILED"), "delivery_id": delivery.get("id"), "updated_at": now_iso()}},
        )
        await db.users.update_one({"id": user["id"]}, {"$set": {"whatsapp_notification_status": delivery.get("status")}})
        await audit_repository.log(
            f"{purpose}_OTP_REQUESTED", "OTP delivery requested", account_id=user["id"], outcome=delivery.get("status", "UNKNOWN")
        )
        return dict(_GENERIC_REQUEST)

    async def verify(self, identifier: str, code: str, purpose: str) -> dict:
        user = await user_repository.get_by_identifier(identifier)
        if user is None or not await self._eligible(user, purpose):
            raise HTTPException(400, {"status": "OTP_INVALID", "message": "Invalid or expired OTP"})
        challenge = await db.auth_challenges.find_one(
            {"user_id": user["id"], "purpose": purpose, "status": "PENDING"}, sort=[("created_epoch", -1)]
        )
        now_epoch = int(time.time())
        if not challenge or challenge.get("expires_epoch", 0) < now_epoch:
            raise HTTPException(400, {"status": "OTP_EXPIRED", "message": "Invalid or expired OTP"})
        max_attempts = int(challenge.get("max_attempts", self._settings()[2]))
        if int(challenge.get("attempts", 0)) >= max_attempts:
            raise HTTPException(400, {"status": "OTP_INVALID", "message": "Invalid or expired OTP"})
        valid = verify_otp(code, challenge.get("otp_hash", ""), purpose=purpose, user_id=user["id"], challenge_id=challenge["id"])
        if not valid:
            await db.auth_challenges.update_one(
                {"id": challenge["id"], "status": "PENDING", "attempts": {"$lt": max_attempts}},
                [{"$set": {"attempts": {"$add": [{"$ifNull": ["$attempts", 0]}, 1]}, "status": {"$cond": [{"$gte": [{"$add": [{"$ifNull": ["$attempts", 0]}, 1]}, max_attempts]}, "LOCKED", "PENDING"]}, "updated_at": now_iso()}}],
            )
            raise HTTPException(400, {"status": "OTP_INVALID", "message": "Invalid or expired OTP"})

        authorization = jwt.encode(
            {
                "sub": user["id"],
                "purpose": purpose,
                "challenge_id": challenge["id"],
                "jti": new_id(),
                "token_type": "password_authorization",
                "aud": "siteseva-password-setup",
                "exp": _now() + timedelta(minutes=10),
                "iat": _now(),
            },
            JWT_SECRET,
            algorithm=JWT_ALGORITHM,
        )
        claimed = await db.auth_challenges.find_one_and_update(
            {"id": challenge["id"], "status": "PENDING", "expires_epoch": {"$gte": now_epoch}, "attempts": {"$lt": max_attempts}},
            {"$set": {"status": "VERIFIED", "verified_at": now_iso(), "authorization_token_hash": _token_hash(authorization), "authorization_expires_at": _now() + timedelta(minutes=10)}},
            return_document=ReturnDocument.AFTER,
        )
        if not claimed:
            raise HTTPException(400, {"status": "OTP_INVALID", "message": "Invalid or expired OTP"})
        await audit_repository.log(f"{purpose}_OTP_VERIFIED", "OTP verified", account_id=user["id"], outcome="VERIFIED")
        return {"ok": True, "status": "ACCEPTED", "authorization_token": authorization, "expires_in": 600}

    async def set_password(self, authorization_token: str, new_password: str, confirm_password: str, purpose: str) -> dict:
        if new_password != confirm_password:
            raise HTTPException(400, "Password confirmation does not match")
        validate_password_strength(new_password)
        try:
            claims = jwt.decode(
                authorization_token,
                JWT_SECRET,
                algorithms=[JWT_ALGORITHM],
                audience="siteseva-password-setup",
            )
        except jwt.PyJWTError:
            raise HTTPException(400, "Invalid or expired password authorization") from None
        if (
            claims.get("token_type") != "password_authorization"
            or claims.get("purpose") != purpose
            or not claims.get("sub")
            or not claims.get("challenge_id")
        ):
            raise HTTPException(400, "Invalid or expired password authorization")
        # A compare-and-set claim makes concurrent/replayed tokens fail closed.
        challenge = await db.auth_challenges.find_one_and_update(
            {"id": claims["challenge_id"], "user_id": claims["sub"], "purpose": purpose, "status": "VERIFIED", "authorization_token_hash": _token_hash(authorization_token), "authorization_expires_at": {"$gte": _now()}},
            {"$set": {"status": "CONSUMING", "consuming_at": now_iso()}},
            return_document=ReturnDocument.AFTER,
        )
        if not challenge:
            raise HTTPException(400, "Invalid or expired password authorization")
        updates = {"password_hash": hash_password(new_password), "must_change_password": False, "password_changed_at": now_iso()}
        if purpose == ACTIVATION:
            updates.update({"password_setup_required": False, "password_setup_completed": True, "password_setup_completed_at": now_iso(), "account_status": "ACTIVE", "status": "ACTIVE"})
        result = await db.users.update_one(
            {"id": claims["sub"], "blocked": {"$ne": True}, "suspended": {"$ne": True}, "disabled": {"$ne": True}, "is_disabled": {"$ne": True}, "status": {"$nin": ["BLOCKED", "SUSPENDED", "REJECTED", "DISABLED", "INACTIVE", "UNAPPROVED"]}, "account_status": {"$nin": ["BLOCKED", "SUSPENDED", "REJECTED", "DISABLED", "INACTIVE", "UNAPPROVED"]}},
            {"$set": updates, "$inc": {"password_version": 1}},
        )
        if result.modified_count != 1:
            await db.auth_challenges.update_one({"id": challenge["id"], "status": "CONSUMING"}, {"$set": {"status": "FAILED", "updated_at": now_iso()}})
            raise HTTPException(400, "Account is not eligible to change password")
        await db.auth_challenges.update_one({"id": challenge["id"]}, {"$set": {"status": "USED", "consumed_at": now_iso()}})
        await db.auth_challenges.update_many({"user_id": claims["sub"], "purpose": purpose, "status": {"$in": ["PENDING", "VERIFIED"]}}, {"$set": {"status": "SUPERSEDED", "updated_at": now_iso()}})
        await audit_repository.log(f"{purpose}_PASSWORD_COMPLETED", "Password updated", account_id=claims["sub"], outcome="SUCCESS")
        return {"ok": True, "status": "ACTIVE", "message": "Password saved. You can now sign in."}


auth_challenge_service = AuthChallengeService()
