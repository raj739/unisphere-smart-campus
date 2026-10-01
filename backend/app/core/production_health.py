from __future__ import annotations

from datetime import datetime, timezone


def application_health() -> dict:

    return {
        "status": "healthy",
        "service": "unisphere-backend",
        "timestamp": datetime.now(
            timezone.utc
        ).isoformat(),
    }