from datetime import datetime

from app.api.v1.interventions_v2 import _response
from app.main import app
from app.models.intervention import AcademicIntervention
from app.models.student import Student


def test_legacy_parent_routes_are_registered():
    paths = {route.path for route in app.routes}

    assert "/api/v1/parent/student" in paths
    assert "/api/v1/parent/overview" in paths


def test_intervention_v2_response_adapts_legacy_model():
    intervention = AcademicIntervention(
        id=7,
        student_id=3,
        intervention_type="Attendance support",
        assigned_to="Academic office",
        priority="High",
        reason="Attendance below threshold",
        due_date="2026-10-01",
        status="Open",
        created_date="2026-09-29",
    )
    student = Student(id=3, uni_id="UNI-DEMO-001")

    result = _response(intervention, student)

    assert result["uni_id"] == "UNI-DEMO-001"
    assert result["due_date"] == "2026-10-01"
    assert result["created_at"] == datetime(2026, 9, 29)
