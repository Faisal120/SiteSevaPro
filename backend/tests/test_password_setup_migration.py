import bcrypt
import asyncio
import os

# Prevent test imports from parsing an external SRV MongoDB URI.
os.environ["MONGO_URL"] = "mongodb://127.0.0.1:27017"
os.environ.setdefault("DB_NAME", "siteseva_test")

from scripts.migrate_password_setup import classify_user, valid_bcrypt_hash
from services.account_status import account_is_denied
import services.auth_challenge_service as challenge_module
from services.auth_challenge_service import ACTIVATION, AuthChallengeService


def valid_hash() -> str:
    return bcrypt.hashpw(b"test-password", bcrypt.gensalt()).decode()


def base_user(**overrides):
    user = {"id": "u1", "email": "user@example.com", "password_hash": valid_hash(), "role": "CONTRACTOR"}
    user.update(overrides)
    return user


def test_legacy_super_admin_keeps_normal_login_state():
    decision = classify_user(base_user(role="SUPER_ADMIN", must_change_password=False))
    assert decision["category"] == "completed"
    assert decision["set"] == {"password_setup_required": False, "password_setup_completed": True}


def test_approved_legacy_contractors_with_temporary_password_require_activation():
    approved = {"id": "application-1", "status": "APPROVED"}
    for user_id in ("contractor-1", "contractor-2"):
        decision = classify_user(base_user(id=user_id, must_change_password=True, application_id="application-1"), approved)
        assert decision["category"] == "eligible_activation"
        assert decision["set"]["password_setup_required"] is True
        assert decision["set"]["password_setup_completed"] is False
        assert decision["inc"] == {"password_version": 1}


def test_missing_status_is_not_treated_as_blocked_or_unapproved():
    user = base_user(must_change_password=False)
    assert not account_is_denied(user)
    assert classify_user(user)["category"] == "completed"


def test_blocked_legacy_contractor_is_skipped_even_with_approved_application():
    decision = classify_user(base_user(must_change_password=True, blocked=True), {"status": "APPROVED"})
    assert decision["category"] == "skipped"
    assert decision["reason"] == "blocked_or_ineligible"


def test_rejected_or_unapproved_application_is_ambiguous_not_activation():
    decision = classify_user(base_user(must_change_password=True), {"status": "REJECTED"})
    assert decision["category"] == "ambiguous"
    assert not decision["set"]


def test_malformed_hash_is_skipped_without_changing_it():
    user = base_user(password_hash="not-a-bcrypt-hash", must_change_password=True)
    assert not valid_bcrypt_hash(user["password_hash"])
    decision = classify_user(user, {"status": "APPROVED"})
    assert decision["category"] == "skipped"
    assert decision["reason"] == "missing_or_malformed_password_hash"


def test_repeated_migration_is_idempotent_for_activation_state():
    user = base_user(must_change_password=True)
    first = classify_user(user, {"status": "APPROVED"})
    user.update(first["set"])
    user["password_version"] = user.get("password_version", 0) + first["inc"].get("password_version", 0)
    second = classify_user(user, {"status": "APPROVED"})
    assert second["category"] == "eligible_activation"
    assert second["set"] == {}
    assert second["inc"] == {}


def test_activation_api_eligibility_accepts_only_approved_migrated_contractor(monkeypatch):
    class Applications:
        async def find_one(self, *_args, **_kwargs):
            return {"status": "APPROVED"}

    class FakeDb:
        applications = Applications()

    monkeypatch.setattr(challenge_module, "db", FakeDb())
    user = base_user(password_setup_required=True, password_setup_completed=False, account_status="PASSWORD_SETUP_REQUIRED", phone="+919876543210", application_id="application-1")
    assert asyncio.run(AuthChallengeService()._eligible(user, ACTIVATION))

    class RejectedApplications:
        async def find_one(self, *_args, **_kwargs):
            return {"status": "REJECTED"}

    class RejectedDb:
        applications = RejectedApplications()

    monkeypatch.setattr(challenge_module, "db", RejectedDb())
    assert not asyncio.run(AuthChallengeService()._eligible(user, ACTIVATION))
