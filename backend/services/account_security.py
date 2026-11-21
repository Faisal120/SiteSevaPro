"""Account security helpers shared by onboarding and password recovery."""
from __future__ import annotations

import hashlib
import hmac
import re
import secrets
import string

from fastapi import HTTPException

from core import JWT_SECRET


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
    return f"{secrets.randbelow(1_000_000):06d}"


def hash_reset_code(code: str) -> str:
    return hmac.new(
        JWT_SECRET.encode(),
        code.encode(),
        hashlib.sha256,
    ).hexdigest()


def verify_reset_code(code: str, expected_hash: str) -> bool:
    return hmac.compare_digest(hash_reset_code(code), expected_hash or "")


def mask_phone(phone: str) -> str:
    if len(phone or "") < 6:
        return "••••"
    return f"{phone[:3]}••••••{phone[-3:]}"
