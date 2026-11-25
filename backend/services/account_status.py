"""Shared, side-effect-free account eligibility rules."""
from __future__ import annotations

DENIED_ACCOUNT_STATES = {"BLOCKED", "SUSPENDED", "REJECTED", "DISABLED", "INACTIVE", "UNAPPROVED"}


def account_is_denied(user: dict) -> bool:
    """Missing legacy status fields are neutral, never a denial by themselves."""
    if any(user.get(flag) is True for flag in ("blocked", "suspended", "disabled", "is_disabled")):
        return True
    if user.get("active") is False or user.get("is_active") is False:
        return True
    return any(
        str(user.get(field, "")).upper() in DENIED_ACCOUNT_STATES
        for field in ("status", "account_status")
        if user.get(field) is not None
    )
