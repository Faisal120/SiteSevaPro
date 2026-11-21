import time
from datetime import datetime, timedelta, timezone

from fastapi import HTTPException

from repositories.user_repository import user_repository

from core import (
    create_jwt,
    db,
    hash_password,
    new_id,
    now_iso,
    verify_password,
    )
from services.account_security import (
    generate_reset_code,
    hash_reset_code,
    validate_password_strength,
    verify_reset_code,
)
from services.outbound_notification_service import outbound_notification_service

class AuthService:

    async def login(
        self,
        email: str,
        password: str,
    ):

        user = await user_repository.get_by_identifier(email)

        if user is None:
            raise HTTPException(
                status_code=401,
                detail="Invalid credentials",
            )

        if not verify_password(
            password,
            user["password_hash"],
        ):
            raise HTTPException(
                status_code=401,
                detail="Invalid credentials",
            )

        if user.get("blocked"):
            raise HTTPException(
                status_code=403,
                detail="Account blocked",
            )

        token = create_jwt(
            {
                "sub": user["id"],
                "role": user["role"],
                "pwdv": int(user.get("password_version", 0)),
            }
        )

        return {
            "token": token,
            "user": user,
        }

    async def current_user(
        self,
        user_id: str,
    ):

        user = await user_repository.get_by_id(
            user_id
        )

        if user is None:
            raise HTTPException(
                status_code=404,
                detail="User not found",
            )


        return user

    async def forgot_password(self, identifier: str):
        """Issue a short-lived WhatsApp reset code without leaking account existence."""

        generic = {
            "ok": True,
            "message": "If the account exists, a password reset code will be sent to its registered WhatsApp number.",
        }
        user = await user_repository.get_by_identifier(identifier)
        if user is None or user.get("blocked"):
            return generic

        recent = await db.password_reset_codes.count_documents(
            {
                "user_id": user["id"],
                "created_epoch": {"$gte": int(time.time()) - 900},
            }
        )
        if recent >= 3:
            return generic

        code = generate_reset_code()
        now = int(time.time())
        await db.password_reset_codes.update_many(
            {"user_id": user["id"], "status": "PENDING"},
            {"$set": {"status": "SUPERSEDED", "updated_at": now_iso()}},
        )
        reset = {
            "id": new_id(),
            "user_id": user["id"],
            "code_hash": hash_reset_code(code),
            "status": "PENDING",
            "attempts": 0,
            "created_epoch": now,
            "expires_epoch": now + 600,
            "purge_at": datetime.now(timezone.utc) + timedelta(days=1),
            "created_at": now_iso(),
        }
        await db.password_reset_codes.insert_one(reset)
        delivery = await outbound_notification_service.send_password_reset(user, code)
        await db.password_reset_codes.update_one(
            {"id": reset["id"]},
            {"$set": {"delivery_status": delivery.get("status")}},
        )
        return generic

    async def reset_password(
        self,
        identifier: str,
        code: str,
        new_password: str,
    ):
        validate_password_strength(new_password)
        user = await user_repository.get_by_identifier(identifier)
        if user is None:
            raise HTTPException(400, "Invalid or expired reset code")
        reset = await db.password_reset_codes.find_one(
            {
                "user_id": user["id"],
                "status": "PENDING",
            },
            sort=[("created_epoch", -1)],
        )
        if (
            reset is None
            or reset.get("expires_epoch", 0) < int(time.time())
            or reset.get("attempts", 0) >= 5
        ):
            raise HTTPException(400, "Invalid or expired reset code")
        if not verify_reset_code(code, reset.get("code_hash", "")):
            attempts = int(reset.get("attempts", 0)) + 1
            patch = {"attempts": attempts, "updated_at": now_iso()}
            if attempts >= 5:
                patch["status"] = "LOCKED"
            await db.password_reset_codes.update_one(
                {"id": reset["id"]},
                {"$set": patch},
            )
            raise HTTPException(400, "Invalid or expired reset code")

        await db.users.update_one(
            {"id": user["id"]},
            {
                "$set": {
                    "password_hash": hash_password(new_password),
                    "must_change_password": False,
                    "password_changed_at": now_iso(),
                },
                "$inc": {"password_version": 1},
            },
        )
        await db.password_reset_codes.update_many(
            {"user_id": user["id"], "status": "PENDING"},
            {"$set": {"status": "USED", "used_at": now_iso()}},
        )
        return {"ok": True, "message": "Password reset successfully. You can now sign in."}

    


auth_service = AuthService()
