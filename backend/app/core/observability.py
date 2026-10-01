from __future__ import annotations

import logging
import time
import uuid

from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import Response

from app.core.logging_config import set_request_id


logger = logging.getLogger("unisphere.request")


class ObservabilityMiddleware(BaseHTTPMiddleware):

    async def dispatch(
        self,
        request: Request,
        call_next,
    ) -> Response:

        request_id = (
            request.headers.get("X-Request-ID")
            or str(uuid.uuid4())
        )

        set_request_id(request_id)

        start = time.perf_counter()

        try:
            response = await call_next(request)

            elapsed_ms = (
                time.perf_counter() - start
            ) * 1000

            response.headers["X-Request-ID"] = request_id

            logger.info(
                "%s %s -> %s %.2fms",
                request.method,
                request.url.path,
                response.status_code,
                elapsed_ms,
            )

            return response

        except Exception:
            elapsed_ms = (
                time.perf_counter() - start
            ) * 1000

            logger.exception(
                "%s %s -> unhandled exception %.2fms",
                request.method,
                request.url.path,
                elapsed_ms,
            )

            raise