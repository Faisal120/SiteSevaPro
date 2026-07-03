from fastapi import APIRouter, Depends

from models.auth import (
    LoginIn,
    TokenOut,
    UserOut,
    RegisterApplicationIn,
    ApplicationOut,
)

from services.auth_service import auth_service

from core.auth import get_current_user

router = APIRouter(
    prefix="/api/auth",
    tags=["Authentication"],
)

@router.post(
    "/login",
    response_model=TokenOut,
)
async def login(
    body: LoginIn,
):
    return await auth_service.login(
        body.email,
        body.password,
    )


@router.get(
    "/me",
    response_model=UserOut,
)
async def me(
    user=Depends(get_current_user),
):
    return await auth_service.current_user(
        user["id"],
    )

@router.post(
    "/applications",
    response_model=ApplicationOut,
)
async def register_application(
    body: RegisterApplicationIn,
):
    return await auth_service.register_application(
        body,
    )

@router.get(
    "/applications",
)
async def pending_applications():

    return await auth_service.list_pending()


@router.post(
    "/applications/{application_id}/approve",
)
async def approve_application(
    application_id: str,
):
    return await auth_service.approve_application(
        application_id,
    )
    
@router.post(
    "/applications/{application_id}/reject",
)
async def reject_application(
    application_id: str,
):
    return await auth_service.reject_application(
        application_id,
    )