from fastapi import APIRouter, Depends

from models.auth import (
    LoginIn,
    TokenOut,
    UserOut,
    RegisterApplicationIn,
    ApplicationOut,
    ForgotPasswordIn,
    ResetPasswordIn,
    OtpRequestIn,
    OtpVerifyIn,
    PasswordAuthorizationIn,
)

from services.auth_service import auth_service

from services.application_service import application_service

from core import get_current_user, require_roles
from services.rate_limit import rate_limit

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
    _: None = Depends(rate_limit("login", 10, 900)),
):
    return await auth_service.login(
        body.email,
        body.password,
    )


@router.post("/password/forgot")
async def forgot_password(
    body: ForgotPasswordIn,
    _: None = Depends(rate_limit("password-forgot", 5, 900)),
):
    return await auth_service.forgot_password(body.identifier)


@router.post("/activation/request-otp")
async def request_activation_otp(
    body: OtpRequestIn,
    _: None = Depends(rate_limit("activation-request", 5, 3600)),
):
    return await auth_service.request_activation_otp(body.identifier)


@router.post("/activation/verify-otp")
async def verify_activation_otp(
    body: OtpVerifyIn,
    _: None = Depends(rate_limit("activation-verify", 10, 900)),
):
    return await auth_service.verify_activation_otp(body.identifier, body.code)


@router.post("/activation/set-password")
async def set_activation_password(
    body: PasswordAuthorizationIn,
    _: None = Depends(rate_limit("activation-password", 10, 900)),
):
    return await auth_service.set_activation_password(**body.model_dump())


@router.post("/password/reset/verify-otp")
async def verify_reset_otp(
    body: OtpVerifyIn,
    _: None = Depends(rate_limit("password-reset-verify", 10, 900)),
):
    return await auth_service.verify_reset_otp(body.identifier, body.code)


@router.post("/password/reset/set-password")
async def set_reset_password(
    body: PasswordAuthorizationIn,
    _: None = Depends(rate_limit("password-reset-password", 10, 900)),
):
    return await auth_service.set_reset_password(**body.model_dump())


@router.post("/password/reset")
async def reset_password(
    body: ResetPasswordIn,
    _: None = Depends(rate_limit("password-reset", 10, 900)),
):
    return await auth_service.reset_password(
        body.identifier,
        body.code,
        body.new_password,
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
    _: None = Depends(rate_limit("registration", 3, 3600)),
):
    return await application_service.submit_application(body)



@router.get(
    "/applications",
)
async def pending_applications(
    _: dict = Depends(require_roles("SUPER_ADMIN")),
):
    return await application_service.list_pending()


@router.post(
    "/applications/{application_id}/approve",
)
async def approve_application(
    application_id: str,
    admin: dict = Depends(require_roles("SUPER_ADMIN")),
):
    return await application_service.approve(
        application_id,
        reviewed_by=admin["id"],
    )
    
@router.post(
    "/applications/{application_id}/reject",
)
async def reject_application(
    application_id: str,
    admin: dict = Depends(require_roles("SUPER_ADMIN")),
):
    return await application_service.reject(
        application_id,
        reviewed_by=admin["id"],
    )
