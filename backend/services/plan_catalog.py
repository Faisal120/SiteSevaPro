"""Canonical commercial plan metadata used by API enforcement and payments."""
from __future__ import annotations

import os


def _int(name: str, default: int) -> int:
    value = os.getenv(name, str(default)).strip()
    return int(value) if value.isdigit() else default


PLAN_CATALOG = {
    "FREE": {"code": "FREE", "name": "Free", "price": 0, "trial_days": _int("FREE_TRIAL_DAYS", 30), "max_sites": _int("FREE_MAX_SITES", 1), "max_supervisors": _int("FREE_MAX_SUPERVISORS", 2), "storage_gb": _int("FREE_STORAGE_GB", 2), "monthly_design_credits": _int("FREE_MONTHLY_DESIGN_CREDITS", 25)},
    "PREMIUM": {"code": "PREMIUM", "name": "Premium", "price": _int("PREMIUM_MONTHLY_PRICE", 2999), "trial_days": 0, "max_sites": None, "max_supervisors": None, "storage_gb": _int("PREMIUM_STORAGE_GB", 20), "monthly_design_credits": _int("PREMIUM_MONTHLY_DESIGN_CREDITS", 250)},
    "ENTERPRISE": {"code": "ENTERPRISE", "name": "Enterprise", "price": _int("ENTERPRISE_MONTHLY_PRICE", 4999), "trial_days": 0, "max_sites": None, "max_supervisors": None, "storage_gb": _int("ENTERPRISE_STORAGE_GB", 100), "monthly_design_credits": _int("ENTERPRISE_MONTHLY_DESIGN_CREDITS", 1000)},
}


def canonical_plan(plan: str | None) -> str:
    # Legacy PRO records are deliberately normalised to PREMIUM.
    return "PREMIUM" if str(plan or "").upper() == "PRO" else str(plan or "FREE").upper()


def plan_details(plan: str | None) -> dict:
    return PLAN_CATALOG.get(canonical_plan(plan), PLAN_CATALOG["FREE"])
