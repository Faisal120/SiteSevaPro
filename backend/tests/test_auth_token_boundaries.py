"""Security boundaries between public password flows and workspace sessions."""
from __future__ import annotations

import asyncio
import os

import jwt
import pytest
from fastapi import HTTPException
from fastapi.security import HTTPAuthorizationCredentials
from starlette.requests import Request

os.environ.setdefault("MONGO_URL", "mongodb://127.0.0.1:27018")
os.environ.setdefault("DB_NAME", "sitesevapro_auth_test")
os.environ.setdefault("JWT_SECRET", "test-jwt-secret")
os.environ.setdefault("SUPER_ADMIN_EMAIL", "admin@example.test")
os.environ.setdefault("SUPER_ADMIN_PASSWORD", "not-a-production-password")

from core import JWT_ALGORITHM, JWT_SECRET, get_current_user


def test_password_authorization_token_is_not_a_workspace_access_token():
    token = jwt.encode(
        {
            "sub": "user-1",
            "purpose": "PASSWORD_RESET",
            "challenge_id": "challenge-1",
            "token_type": "password_authorization",
            "aud": "siteseva-password-setup",
        },
        JWT_SECRET,
        algorithm=JWT_ALGORITHM,
    )
    request = Request({"type": "http", "method": "GET", "path": "/api/sites", "headers": []})
    credentials = HTTPAuthorizationCredentials(scheme="Bearer", credentials=token)
    with pytest.raises(HTTPException) as error:
        asyncio.run(get_current_user(request, credentials))
    assert error.value.status_code == 401
