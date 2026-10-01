import importlib
from datetime import timedelta
import pytest
from fastapi import HTTPException
from fastapi.security import HTTPAuthorizationCredentials

import app.core.security as security
from app.models.user import User


def test_missing_jwt_secret_in_production_raises_error(monkeypatch):
    monkeypatch.setenv("ENVIRONMENT", "production")
    monkeypatch.delenv("JWT_SECRET_KEY", raising=False)
    with pytest.raises(RuntimeError, match="JWT_SECRET_KEY is required"):
        security.get_jwt_secret()


def test_dev_fallback_jwt_secret(monkeypatch):
    monkeypatch.setenv("ENVIRONMENT", "development")
    monkeypatch.delenv("JWT_SECRET_KEY", raising=False)
    secret = security.get_jwt_secret()
    assert len(secret) >= 32


def test_create_access_token_uses_env_secret(monkeypatch):
    secret = "a-very-secure-dev-secret-key-32-chars-long"
    monkeypatch.setenv("JWT_SECRET_KEY", secret)
    monkeypatch.setenv("ENVIRONMENT", "development")

    token = security.create_access_token({"sub": "42", "role": "student"})
    payload = security.decode_access_token(token)

    assert payload is not None
    assert payload["sub"] == "42"
    assert payload["role"] == "student"


def test_decode_invalid_and_malformed_token():
    assert security.decode_access_token("invalid.jwt.token") is None
    assert security.decode_access_token("not_a_jwt") is None


def test_get_current_user_missing_credentials():
    with pytest.raises(HTTPException) as exc_info:
        security.get_current_user(credentials=None, db=None)
    assert exc_info.value.status_code == 401
    assert exc_info.value.detail == "Not authenticated"


def test_get_current_user_invalid_token():
    creds = HTTPAuthorizationCredentials(scheme="Bearer", credentials="invalid.token.str")
    with pytest.raises(HTTPException) as exc_info:
        security.get_current_user(credentials=creds, db=None)
    assert exc_info.value.status_code == 401
    assert exc_info.value.detail == "Invalid or expired token"


def test_get_current_user_expired_token(monkeypatch):
    secret = "a-very-secure-dev-secret-key-32-chars-long"
    monkeypatch.setenv("JWT_SECRET_KEY", secret)

    token = security.create_access_token(
        {"sub": "42", "role": "student"},
        expires_delta=timedelta(seconds=-10),
    )
    creds = HTTPAuthorizationCredentials(scheme="Bearer", credentials=token)
    with pytest.raises(HTTPException) as exc_info:
        security.get_current_user(credentials=creds, db=None)
    assert exc_info.value.status_code == 401


def test_get_current_user_non_int_sub(monkeypatch):
    secret = "a-very-secure-dev-secret-key-32-chars-long"
    monkeypatch.setenv("JWT_SECRET_KEY", secret)

    token = security.create_access_token({"sub": "not_an_int", "role": "student"})
    creds = HTTPAuthorizationCredentials(scheme="Bearer", credentials=token)
    with pytest.raises(HTTPException) as exc_info:
        security.get_current_user(credentials=creds, db=None)
    assert exc_info.value.status_code == 401
    assert exc_info.value.detail == "Invalid user ID in token payload"

