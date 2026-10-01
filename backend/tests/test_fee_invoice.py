import re
from datetime import datetime, timezone

from app.api.v1.fees_v2 import new_invoice_number
from app.schemas.examination_v2 import ExaminationRegistrationResponse


def test_invoice_numbers_are_readable_and_unique():
    first = new_invoice_number()
    second = new_invoice_number()

    assert re.fullmatch(r"UNI-FEE-\d{8}-[A-F0-9]{8}", first)
    assert first != second


def test_exam_registration_serializes_database_timestamps():
    timestamp = datetime.now(timezone.utc)
    registration = ExaminationRegistrationResponse(
        id=1,
        examination_id=2,
        student_id=3,
        registration_number="EXAM-2-3",
        status="approved",
        registered_at=timestamp,
        approved_at=timestamp,
    )

    payload = registration.model_dump(mode="json")
    assert payload["registered_at"] == timestamp.isoformat()
    assert payload["approved_at"] == timestamp.isoformat()
