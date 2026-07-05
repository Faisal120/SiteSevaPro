from fastapi import HTTPException

from repositories.user_repository import user_repository

from core import (
    create_jwt,
    verify_password,
    )

class AuthService:

    async def login(
        self,
        email: str,
        password: str,
    ):

        user = await user_repository.get_by_email(
            email.lower()
        )

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

    async def register_application(
        self,
        payload,
    ):
        return await user_repository.register_application(
            payload
        )

    async def approve_application(
        self,
        application_id: str,
    ):
        return await user_repository.approve_application(
            application_id
        )

    async def reject_application(
        self,
        application_id: str,
    ):
        return await user_repository.reject_application(
            application_id
        )


auth_service = AuthService()