import re

import pytest
from fastapi import HTTPException

from services.account_security import (
    generate_otp,
    generate_temporary_password,
    hash_otp,
    hash_reset_code,
    normalize_phone,
    validate_password_strength,
    verify_reset_code,
    verify_otp,
)
from services.whatsapp_templates import authentication_components


@pytest.mark.parametrize(
    ("raw", "expected"),
    [
        ("98765 43210", "+919876543210"),
        ("+91-98765-43210", "+919876543210"),
        ("0091 98765 43210", "+919876543210"),
        ("14155552671", "+14155552671"),
    ],
)
def test_normalize_phone(raw, expected):
    assert normalize_phone(raw) == expected


@pytest.mark.parametrize("raw", ["", "123", "abcdefghij", "+1234567890123456"])
def test_normalize_phone_rejects_invalid_values(raw):
    with pytest.raises(ValueError):
        normalize_phone(raw)


def test_generated_temporary_password_meets_policy():
    password = generate_temporary_password()
    assert len(password) >= 12
    assert re.search(r"[A-Z]", password)
    assert re.search(r"[a-z]", password)
    assert re.search(r"\d", password)
    assert re.search(r"[^A-Za-z0-9]", password)
    assert validate_password_strength(password) == password


@pytest.mark.parametrize(
    "password",
    ["short", "alllowercase123!", "ALLUPPERCASE123!", "NoNumberHere!", "NoSpecial1234"],
)
def test_password_policy_rejects_weak_passwords(password):
    with pytest.raises(HTTPException):
        validate_password_strength(password)


def test_reset_codes_are_hashed_and_constant_time_verified(monkeypatch):
    monkeypatch.setenv("JWT_SECRET", "unit-test-secret-that-is-never-used-in-production")
    digest = hash_reset_code("123456")
    assert digest != "123456"
    assert verify_reset_code("123456", digest)
    assert not verify_reset_code("654321", digest)


def test_otp_hash_is_bound_to_user_purpose_and_challenge(monkeypatch):
    monkeypatch.setenv("AUTH_CHALLENGE_SECRET", "unit-test-secret-that-is-never-used-in-production")
    code = generate_otp()
    digest = hash_otp(code, purpose="ACTIVATION", user_id="u1", challenge_id="c1")
    assert digest != code
    assert verify_otp(code, digest, purpose="ACTIVATION", user_id="u1", challenge_id="c1")
    assert not verify_otp(code, digest, purpose="PASSWORD_RESET", user_id="u1", challenge_id="c1")
    assert not verify_otp(code, digest, purpose="ACTIVATION", user_id="u2", challenge_id="c1")


def test_copy_code_template_components_have_body_and_button():
    components = authentication_components("123456")
    assert components == [
        {"type": "body", "parameters": [{"type": "text", "text": "123456"}]},
        {"type": "button", "sub_type": "url", "index": "0", "parameters": [{"type": "text", "text": "123456"}]},
    ]
