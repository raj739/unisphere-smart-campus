from __future__ import annotations

import logging
from typing import Any

from fastapi import HTTPException, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse

from app.core.logging_config import get_request_id


logger = logging.getLogger("unisphere.errors")


def _error_response(
    status_code: int,
    code: str,
    message: str,
    details: Any = None,
):
    error = {
        "code": code,
        "message": message,
        "request_id": get_request_id(),
    }

    if details is not None:
        error["details"] = details

    return JSONResponse(
        status_code=status_code,
        content={
            "success": False,
            "error": error,
        },
    )


async def http_exception_handler(
    request: Request,
    exc: HTTPException,
):
    logger.warning(
        "HTTP error: %s %s -> %s",
        request.method,
        request.url.path,
        exc.status_code,
    )

    return _error_response(
        exc.status_code,
        "HTTP_ERROR",
        str(exc.detail),
    )


async def validation_exception_handler(
    request: Request,
    exc: RequestValidationError,
):
    logger.warning(
        "Validation error: %s %s",
        request.method,
        request.url.path,
    )

    return _error_response(
        422,
        "VALIDATION_ERROR",
        "Request validation failed.",
        exc.errors(),
    )


async def unhandled_exception_handler(
    request: Request,
    exc: Exception,
):
    logger.exception(
        "Unhandled server exception: %s %s",
        request.method,
        request.url.path,
    )

    return _error_response(
        500,
        "INTERNAL_SERVER_ERROR",
        "An unexpected server error occurred.",
    )
# =========================================================
# Compatibility API
# =========================================================

def register_error_handlers(app):
    """
    Compatibility wrapper used by UniSphere startup/preflight code.

    The module already contains the individual exception handlers.
    This function registers the available handlers on a FastAPI app
    without replacing the existing implementations.
    """
    from fastapi import HTTPException, Request
    from fastapi.exceptions import RequestValidationError
    from starlette.exceptions import HTTPException as StarletteHTTPException

    try:
        app.add_exception_handler(
            RequestValidationError,
            validation_exception_handler,
        )
    except NameError:
        pass

    try:
        app.add_exception_handler(
            HTTPException,
            http_exception_handler,
        )
    except NameError:
        try:
            app.add_exception_handler(
                StarletteHTTPException,
                http_exception_handler,
            )
        except NameError:
            pass

    try:
        app.add_exception_handler(
            Exception,
            unhandled_exception_handler,
        )
    except NameError:
        pass

    return app