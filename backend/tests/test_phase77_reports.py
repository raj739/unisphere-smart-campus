from app.services.report_service import ReportService


def test_pdf_generation():
    data = ReportService.build_pdf(
        title="Test Report",
        rows=[
            {
                "Name": "Aarav",
                "Score": 90,
            }
        ],
        metadata={
            "Module": "Phase 77",
        },
    )

    assert isinstance(data, bytes)
    assert data.startswith(b"%PDF")


def test_excel_generation():
    data = ReportService.build_excel(
        title="Test Report",
        rows=[
            {
                "Name": "Aarav",
                "Score": 90,
            }
        ],
    )

    assert isinstance(data, bytes)
    assert len(data) > 100


def test_student_summary():
    class Student:
        name = "Aarav Sharma"
        uni_id = "UNI-MP-VU-BCA-2026-001247"
        enrollment_number = "VU2024BCA1247"

    rows = ReportService.student_summary(Student())

    assert len(rows) == 3
    assert rows[0]["Value"] == "Aarav Sharma"