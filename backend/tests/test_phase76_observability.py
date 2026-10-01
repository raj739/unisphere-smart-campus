from app.core.logging_config import (
    configure_logging,
    get_request_id,
    set_request_id,
)

from app.core.observability import ObservabilityMiddleware

from app.core.error_handlers import (
    http_exception_handler,
    validation_exception_handler,
    unhandled_exception_handler,
)


def test_request_id_context():
    set_request_id("phase76-test")
    assert get_request_id() == "phase76-test"


def test_logging_configuration():
    configure_logging()
    configure_logging()
    assert True


def test_observability_middleware():
    assert ObservabilityMiddleware is not None


def test_error_handlers():
    assert http_exception_handler is not None
    assert validation_exception_handler is not None
    assert unhandled_exception_handler is not None