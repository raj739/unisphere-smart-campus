from pathlib import Path

from app.core.production_settings import (
    get_production_settings,
    validate_production_settings,
)

from app.core.production_health import (
    application_health,
)


BACKEND = Path(__file__).resolve().parents[1]


def test_production_settings_load():
    settings = get_production_settings()

    assert settings.app_name
    assert settings.environment


def test_production_validation_development_safe():
    settings = validate_production_settings()

    assert settings.app_name == "UniSphere"


def test_health():
    result = application_health()

    assert result["status"] == "healthy"
    assert result["service"] == "unisphere-backend"


def test_deployment_files_exist():

    required = [
        BACKEND / "Dockerfile",
        BACKEND / "docker-compose.production.yml",
        BACKEND / ".env.production.example",
        BACKEND / ".dockerignore",
        BACKEND / "deployment" / "README.md",
    ]

    for path in required:
        assert path.exists(), f"Missing deployment file: {path}"