"""Account security helpers shared by onboarding and password recovery."""
from __future__ import annotations

import hashlib
import hmac
import os
import re
import secrets
import string

from fastapi import HTTPException

PASSWORD_MIN_LENGTH = 12


def normalize_phone(value: str, default_country_code: str = "91") -> str:
    """Return a WhatsApp-ready E.164 number.

    SiteSeva currently operates in India, so a 10 digit local number is
    normalized to +91. International numbers must already include a country
    code (with or without the leading plus sign).
    """

    raw = (value or "").strip()
    digits = re.sub(r"\D", "", raw)
    if raw.startswith("00"):
        digits = digits[2:]
    if len(digits) == 10:
        digits = f"{default_country_code}{digits}"
    if not 8 <= len(digits) <= 15:
        raise ValueError("Enter a valid WhatsApp number with country code")
    return f"+{digits}"


def validate_password_strength(password: str) -> str:
    errors = []
    if len(password or "") < PASSWORD_MIN_LENGTH:
        errors.append(f"at least {PASSWORD_MIN_LENGTH} characters")
    if not re.search(r"[A-Z]", password or ""):
        errors.append("one uppercase letter")
    if not re.search(r"[a-z]", password or ""):
        errors.append("one lowercase letter")
    if not re.search(r"\d", password or ""):
        errors.append("one number")
    if not re.search(r"[^A-Za-z0-9]", password or ""):
        errors.append("one special character")
    if errors:
        raise HTTPException(400, "Password must contain " + ", ".join(errors))
    return password


def generate_temporary_password(length: int = 16) -> str:
    """Generate a password that always satisfies the platform policy."""

    alphabet = string.ascii_letters + string.digits + "@#$%&*"
    required = [
        secrets.choice(string.ascii_uppercase),
        secrets.choice(string.ascii_lowercase),
        secrets.choice(string.digits),
        secrets.choice("@#$%&*"),
    ]
    remaining = [secrets.choice(alphabet) for _ in range(max(length - 4, 8))]
    values = required + remaining
    secrets.SystemRandom().shuffle(values)
    return "".join(values)


def generate_reset_code() -> str:
    """Backward-compatible name for a cryptographically secure six-digit OTP."""
    return f"{secrets.randbelow(1_000_000):06d}"


def generate_otp() -> str:
    return generate_reset_code()


def _challenge_secret() -> str:
    secret = (
        os.getenv("AUTH_CHALLENGE_SECRET")
        or os.getenv("PASSWORD_RESET_SECRET")
        or os.getenv("JWT_SECRET")
    )
    if not secret:
        raise RuntimeError("AUTH_CHALLENGE_SECRET or JWT_SECRET is required")
    return secret


def hash_otp(code: str, *, purpose: str, user_id: str, challenge_id: str) -> str:
    """Bind an OTP hash to exactly one account, purpose and challenge."""
    message = f"{purpose}:{user_id}:{challenge_id}:{code}".encode()
    return hmac.new(_challenge_secret().encode(), message, hashlib.sha256).hexdigest()


def verify_otp(
    code: str,
    expected_hash: str,
    *,
    purpose: str,
    user_id: str,
    challenge_id: str,
) -> bool:
    return hmac.compare_digest(
        hash_otp(code, purpose=purpose, user_id=user_id, challenge_id=challenge_id),
        expected_hash or "",
    )


def hash_reset_code(code: str) -> str:
    # Legacy password_reset_codes records were not purpose-bound. Keep this
    # helper only for reading them during a controlled transition.
    return hmac.new(_challenge_secret().encode(), code.encode(), hashlib.sha256).hexdigest()


def verify_reset_code(code: str, expected_hash: str) -> bool:
    return hmac.compare_digest(hash_reset_code(code), expected_hash or "")


def mask_phone(phone: str) -> str:
    if len(phone or "") < 6:
        return "••••"
    return f"{phone[:3]}••••••{phone[-3:]}"
