from __future__ import annotations

import os
from dataclasses import dataclass


@dataclass(frozen=True)
class ProductionSettings:
    app_name: str
    environment: str
    debug: bool
    database_url: str
    allowed_origins: tuple[str, ...]
    jwt_secret: str
    gemini_api_key: str


def _as_bool(value: str | None, default: bool = False) -> bool:
    if value is None:
        return default

    return value.strip().lower() in {
        "1",
        "true",
        "yes",
        "on",
    }


def get_production_settings() -> ProductionSettings:

    database_url = os.getenv(
        "DATABASE_URL",
        "",
    ).strip()

    jwt_secret = os.getenv(
        "JWT_SECRET_KEY",
        "",
    ).strip()

    gemini_api_key = os.getenv(
        "GEMINI_API_KEY",
        "",
    ).strip()

    origins_raw = os.getenv(
        "ALLOWED_ORIGINS",
        "http://localhost:3000",
    )

    origins = tuple(
        item.strip()
        for item in origins_raw.split(",")
        if item.strip()
    )

    return ProductionSettings(
        app_name=os.getenv(
            "APP_NAME",
            "UniSphere",
        ),
        environment=os.getenv(
            "ENVIRONMENT",
            "development",
        ),
        debug=_as_bool(
            os.getenv("DEBUG"),
            False,
        ),
        database_url=database_url,
        allowed_origins=origins,
        jwt_secret=jwt_secret,
        gemini_api_key=gemini_api_key,
    )


def validate_production_settings() -> ProductionSettings:

    settings = get_production_settings()

    if settings.environment.lower() == "production":

        if not settings.database_url:
            raise RuntimeError(
                "DATABASE_URL is required in production."
            )

        if not settings.jwt_secret:
            raise RuntimeError(
                "JWT_SECRET_KEY is required in production."
            )

        if len(settings.jwt_secret) < 32:
            raise RuntimeError(
                "JWT_SECRET_KEY must contain at least 32 characters."
            )

    return settings
