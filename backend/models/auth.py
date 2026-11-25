"""
Authentication Models

Extracted from main.py

SiteSeva Pro
"""

from typing import List, Literal, Optional

from pydantic import BaseModel, EmailStr, Field, field_validator

from services.account_security import normalize_phone


# ==========================================================
# Shared Types
# ==========================================================

Role = Literal[
    "SUPER_ADMIN",
    "CONTRACTOR",
    "SUPERVISOR",
    "CLIENT",
]

Plan = Literal[
    "FREE",
    "PRO",
    "PREMIUM",
    "ENTERPRISE",
]

# ==========================================================
# Login
# ==========================================================

class LoginIn(BaseModel):

    # Kept as ``email`` for backward compatibility. Usernames are accepted too.
    email: str = Field(min_length=3, max_length=160)

    password: str


# ==========================================================
# User Response
# ==========================================================

class UserOut(BaseModel):

    id: str

    email: EmailStr

    full_name: str

    role: Role

    username: Optional[str] = None

    company_id: Optional[str] = None

    company_name: Optional[str] = None

    plan: Optional[Plan] = "FREE"

    site_ids: List[str] = Field(default_factory=list)

    blocked: bool = False

    phone: Optional[str] = None

    whatsapp: Optional[str] = None

    must_change_password: bool = False

    password_version: int = 0

    created_at: str


# ==========================================================
# Login Response
# ==========================================================

class TokenOut(BaseModel):

    token: str

    user: UserOut


# ==========================================================
# Contractor Registration
# ==========================================================

class RegisterApplicationIn(BaseModel):

    company_name: str

    owner_name: str

    mobile: str

    email: EmailStr

    office_address: str

    city: str

    state: str

    gst_number: Optional[str] = None

    active_projects: int = 0

    employee_count: int = 0

    @field_validator("mobile")
    @classmethod
    def valid_mobile(cls, value: str) -> str:
        return normalize_phone(value)


class ForgotPasswordIn(BaseModel):

    identifier: str = Field(min_length=3, max_length=160)


class ResetPasswordIn(BaseModel):

    identifier: str = Field(min_length=3, max_length=160)

    code: str = Field(pattern=r"^\d{6}$")

    new_password: str = Field(min_length=12, max_length=256)


class OtpRequestIn(BaseModel):
    identifier: str = Field(min_length=3, max_length=160)


class OtpVerifyIn(BaseModel):
    identifier: str = Field(min_length=3, max_length=160)
    code: str = Field(pattern=r"^\d{6}$")


class PasswordAuthorizationIn(BaseModel):
    authorization_token: str = Field(min_length=20, max_length=4096)
    new_password: str = Field(min_length=12, max_length=256)
    confirm_password: str = Field(min_length=12, max_length=256)


# ==========================================================
# Contractor Application
# ==========================================================

class ApplicationOut(BaseModel):

    id: str

    company_name: str

    owner_name: str

    mobile: str

    email: EmailStr

    office_address: str

    city: str

    state: str

    gst_number: Optional[str] = None

    active_projects: int

    employee_count: int

    status: Literal[
        "PENDING",
        "PROCESSING",
        "APPROVED",
        "REJECTED",
    ]

    created_at: str
