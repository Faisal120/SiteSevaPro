"""
Authentication Models

Extracted from main.py

SiteSeva Pro
"""

from typing import List, Literal, Optional

from pydantic import BaseModel, EmailStr

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
    "PREMIUM",
    "ENTERPRISE",
]

# ==========================================================
# Login
# ==========================================================

class LoginIn(BaseModel):

    email: EmailStr

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

    site_ids: List[str] = []

    blocked: bool = False

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
        "APPROVED",
        "REJECTED",
    ]

    created_at: str