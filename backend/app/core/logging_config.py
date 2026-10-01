from __future__ import annotations

import logging
import sys
from contextvars import ContextVar
from datetime import datetime, timezone


_request_id: ContextVar[str] = ContextVar(
    "unisphere_request_id",
    default="-",
)


class RequestIdFilter(logging.Filter):
    def filter(self, record: logging.LogRecord) -> bool:
        record.request_id = _request_id.get()
        return True


def set_request_id(request_id: str) -> None:
    _request_id.set(request_id)


def get_request_id() -> str:
    return _request_id.get()


def configure_logging() -> None:
    root = logging.getLogger()

    if getattr(root, "_unisphere_logging_configured", False):
        return

    root.setLevel(logging.INFO)

    handler = logging.StreamHandler(sys.stdout)

    formatter = logging.Formatter(
        "%(asctime)s | %(levelname)s | "
        "request_id=%(request_id)s | "
        "%(name)s | %(message)s",
        datefmt="%Y-%m-%dT%H:%M:%S%z",
    )

    handler.setFormatter(formatter)
    handler.addFilter(RequestIdFilter())

    root.addHandler(handler)

    root._unisphere_logging_configured = True


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()