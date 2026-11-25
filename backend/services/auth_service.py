from fastapi import HTTPException

from repositories.user_repository import user_repository

from core import (
    create_jwt,
    verify_password,
    )
from services.auth_challenge_service import ACTIVATION, PASSWORD_RESET, auth_challenge_service
from services.rate_limit import rate_limit_account

class AuthService:

    async def login(
        self,
        email: str,
        password: str,
    ):

        await rate_limit_account("login-account", email, 10, 900)

        user = await user_repository.get_by_identifier(email)

        if user is None:
            raise HTTPException(
                status_code=401,
                detail="Invalid credentials",
            )

        if user.get("password_setup_required"):
            raise HTTPException(status_code=403, detail={"status": "PASSWORD_SETUP_REQUIRED", "message": "Complete password setup before signing in"})
        if not user.get("password_hash") or not verify_password(
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
        await rate_limit_account("forgot-account", identifier, 5, 3600)
        return await auth_challenge_service.request(identifier, PASSWORD_RESET)

    async def reset_password(
        self,
        identifier: str,
        code: str,
        new_password: str,
    ):
        # Existing endpoint remains for older clients. New clients must use
        # verify-otp + set-password so the authorization is single-use.
        verified = await auth_challenge_service.verify(identifier, code, PASSWORD_RESET)
        return await auth_challenge_service.set_password(verified["authorization_token"], new_password, new_password, PASSWORD_RESET)

    async def request_activation_otp(self, identifier: str):
        await rate_limit_account("activation-account", identifier, 5, 3600)
        return await auth_challenge_service.request(identifier, ACTIVATION)

    async def verify_activation_otp(self, identifier: str, code: str):
        return await auth_challenge_service.verify(identifier, code, ACTIVATION)

    async def set_activation_password(self, **payload):
        return await auth_challenge_service.set_password(purpose=ACTIVATION, **payload)

    async def verify_reset_otp(self, identifier: str, code: str):
        return await auth_challenge_service.verify(identifier, code, PASSWORD_RESET)

    async def set_reset_password(self, **payload):
        return await auth_challenge_service.set_password(purpose=PASSWORD_RESET, **payload)

    


auth_service = AuthService()
