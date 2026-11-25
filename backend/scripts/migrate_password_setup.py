#!/usr/bin/env python3
"""Safely classify legacy password state for the OTP activation migration.

The default is read-only.  This script never reads password values, changes a
password hash, sends notifications, or deletes documents.
"""
from __future__ import annotations

import argparse
import asyncio
from collections import Counter
import os
import sys
from pathlib import Path
from typing import Any

import bcrypt
from dotenv import load_dotenv
from motor.motor_asyncio import AsyncIOMotorClient

BACKEND_DIR = Path(__file__).resolve().parents[1]
if str(BACKEND_DIR) not in sys.path:
    sys.path.insert(0, str(BACKEND_DIR))
from services.account_status import account_is_denied

def valid_bcrypt_hash(value: object) -> bool:
    """Validate the project bcrypt format without exposing or modifying a hash."""
    if not isinstance(value, str) or not value.startswith(("$2a$", "$2b$", "$2y$")):
        return False
    try:
        # bcrypt returns False for the probe; malformed encodings raise ValueError.
        bcrypt.checkpw(b"migration-format-probe", value.encode("utf-8"))
        return True
    except (ValueError, TypeError):
        return False


def _is_blocked_or_ineligible(user: dict[str, Any]) -> bool:
    return account_is_denied(user)


def _approved_application(application: dict[str, Any] | None) -> bool:
    return bool(application and str(application.get("status", "")).upper() == "APPROVED")


def classify_user(user: dict[str, Any], application: dict[str, Any] | None = None) -> dict[str, Any]:
    """Return a safe, deterministic migration category and additive update.

    Only legacy contractors with a valid bcrypt hash, `must_change_password`,
    and an approved linked application become activation accounts.  Missing
    `account_status` by itself never makes an account blocked or unapproved.
    """
    if _is_blocked_or_ineligible(user):
        return {"category": "skipped", "reason": "blocked_or_ineligible", "set": {}, "inc": {}}
    if not valid_bcrypt_hash(user.get("password_hash")):
        return {"category": "skipped", "reason": "missing_or_malformed_password_hash", "set": {}, "inc": {}}

    required = user.get("password_setup_required")
    completed = user.get("password_setup_completed")
    must_change = user.get("must_change_password")

    # Explicit new state is authoritative when internally consistent.
    if required is True and completed is False:
        return {"category": "eligible_activation", "reason": "existing_activation_state", "set": {}, "inc": {}}
    if required is False and completed is True and must_change is not True:
        return {"category": "completed", "reason": "existing_completed_state", "set": {}, "inc": {}}
    if required is not None or completed is not None:
        return {"category": "ambiguous", "reason": "conflicting_existing_password_setup_state", "set": {}, "inc": {}}

    # Super Admin must keep access; legacy must_change is not interpreted as
    # an incomplete contractor invitation for this privileged account.
    if user.get("role") == "SUPER_ADMIN":
        return {
            "category": "completed",
            "reason": "legacy_super_admin",
            "set": {"password_setup_required": False, "password_setup_completed": True},
            "inc": {},
        }

    if must_change is False or must_change is None:
        return {
            "category": "completed",
            "reason": "legacy_normal_password",
            "set": {"password_setup_required": False, "password_setup_completed": True},
            "inc": {},
        }

    if user.get("role") == "CONTRACTOR" and must_change is True:
        if not _approved_application(application):
            return {"category": "ambiguous", "reason": "legacy_contractor_without_approved_application", "set": {}, "inc": {}}
        return {
            "category": "eligible_activation",
            "reason": "approved_legacy_contractor_must_change_password",
            "set": {
                "password_setup_required": True,
                "password_setup_completed": False,
                "account_status": "PASSWORD_SETUP_REQUIRED",
                "must_change_password": True,
            },
            # Existing JWTs must not continue to work after activation is required.
            "inc": {"password_version": 1},
        }
    return {"category": "ambiguous", "reason": "legacy_must_change_without_verified_contractor_application", "set": {}, "inc": {}}


async def find_linked_application(database, user: dict[str, Any]) -> dict[str, Any] | None:
    application_id = user.get("application_id")
    if application_id:
        return await database.applications.find_one({"id": application_id}, {"_id": 0, "status": 1, "id": 1})
    # Legacy approval records may have stored user_id instead of application_id.
    application = await database.applications.find_one({"user_id": user.get("id")}, {"_id": 0, "status": 1, "id": 1})
    if application:
        return application
    email = user.get("email")
    return await database.applications.find_one({"email": str(email or "").lower()}, {"_id": 0, "status": 1, "id": 1})


async def review_legacy_notifications(database) -> int:
    """Count only metadata; never retrieve or print historic message content."""
    return await database.outbound_notifications.count_documents(
        {"$or": [{"event": "ACCOUNT_CREDENTIALS"}, {"template_name": "siteseva_account_credentials"}]}
    )


async def run(*, apply: bool, confirmed_database: str | None = None) -> dict[str, Any]:
    load_dotenv()
    url = os.getenv("MONGO_URL") or os.getenv("MONGODB_URI")
    name = os.getenv("DB_NAME")
    if not url or not name:
        raise SystemExit("MONGO_URL (or MONGODB_URI) and DB_NAME are required")
    if apply and confirmed_database != name:
        raise SystemExit("Refusing to apply: pass --confirm-db with the exact configured DB_NAME")

    client = AsyncIOMotorClient(url)
    database = client[name]
    report: Counter[str] = Counter()
    reasons: Counter[str] = Counter()
    changed = 0
    try:
        projection = {
            "id": 1, "email": 1, "role": 1, "application_id": 1,
            "password_hash": 1, "password_version": 1, "must_change_password": 1,
            "password_setup_required": 1, "password_setup_completed": 1,
            "account_status": 1, "status": 1, "blocked": 1, "suspended": 1,
            "disabled": 1, "is_disabled": 1, "active": 1, "is_active": 1,
        }
        async for user in database.users.find({}, projection):
            application = await find_linked_application(database, user) if user.get("role") == "CONTRACTOR" and user.get("must_change_password") else None
            decision = classify_user(user, application)
            report[decision["category"]] += 1
            reasons[decision["reason"]] += 1
            if not decision["set"] and not decision["inc"]:
                continue
            changed += 1
            if apply:
                update: dict[str, Any] = {"$set": decision["set"]}
                if decision["inc"]:
                    update["$inc"] = decision["inc"]
                await database.users.update_one({"_id": user["_id"]}, update)
        legacy_notifications = await review_legacy_notifications(database)
    finally:
        client.close()
    result = {"mode": "apply" if apply else "dry_run", "database": name, "changed": changed, "categories": dict(report), "reasons": dict(reasons), "legacy_credential_notification_records": legacy_notifications}
    print(f"{result['mode']}: {changed} user documents would be updated." if not apply else f"apply: {changed} user documents updated.")
    print("categories:", dict(report))
    print("reasons:", dict(reasons))
    print(f"legacy credential notification metadata records: {legacy_notifications}")
    print("Remediation: retain records for audit, restrict access, and apply the approved retention policy; this script never reads message content or deletes records.")
    return result


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--apply", action="store_true", help="perform additive updates (default is dry run)")
    parser.add_argument("--confirm-db", help="required with --apply; must exactly equal configured DB_NAME")
    args = parser.parse_args()
    asyncio.run(run(apply=args.apply, confirmed_database=args.confirm_db))
