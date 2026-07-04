from fastapi import HTTPException

from repositories.user_repository import user_repository

# Existing helper functions ko yahin import karo
# (ye tumhari current main.py me already hain)

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
        ...

    async def current_user(
        self,
        user_id: str,
    ):
        ...

    async def register_application(
        self,
        payload,
    ):
        ...

    async def approve_application(
        self,
        application_id: str,
    ):
        ...

    async def reject_application(
        self,
        application_id: str,
    ):
        ...


auth_service = AuthService()