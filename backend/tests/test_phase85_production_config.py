import os
import pytest
from app.core.production_settings import get_production_settings, validate_production_settings
from app.main import app


def test_production_settings_validation_missing_db(monkeypatch):
    monkeypatch.setenv("ENVIRONMENT", "production")
    monkeypatch.delenv("DATABASE_URL", raising=False)
    monkeypatch.setenv("JWT_SECRET_KEY", "a-very-long-production-jwt-secret-key-32-chars")

    with pytest.raises(RuntimeError, match="DATABASE_URL is required"):
        validate_production_settings()


def test_production_settings_validation_missing_jwt(monkeypatch):
    monkeypatch.setenv("ENVIRONMENT", "production")
    monkeypatch.setenv("DATABASE_URL", "postgresql+psycopg://user:pass@host:5432/db")
    monkeypatch.delenv("JWT_SECRET_KEY", raising=False)

    with pytest.raises(RuntimeError, match="JWT_SECRET_KEY is required"):
        validate_production_settings()


def test_production_settings_valid(monkeypatch):
    monkeypatch.setenv("ENVIRONMENT", "production")
    monkeypatch.setenv("DATABASE_URL", "postgresql+psycopg://user:pass@host:5432/db")
    monkeypatch.setenv("JWT_SECRET_KEY", "a-very-long-production-jwt-secret-key-32-chars")
    monkeypatch.setenv("ALLOWED_ORIGINS", "http://localhost:3000,https://app.unisphere.edu")

    settings = validate_production_settings()
    assert settings.environment == "production"
    assert "https://app.unisphere.edu" in settings.allowed_origins


def test_cors_middleware_present():
    middleware_names = [m.cls.__name__ for m in app.user_middleware]
    assert "CORSMiddleware" in middleware_names
