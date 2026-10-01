import pytest
from app.services.report_service import ReportService


def test_pdf_generation():
    rows = [
        {"ID": "STU101", "Name": "Student A", "GPA": "3.8"},
        {"ID": "STU102", "Name": "Student B", "GPA": "3.9"},
    ]
    metadata = {"GeneratedBy": "Admin", "Campus": "Main Campus"}

    pdf_bytes = ReportService.build_pdf("Academic Progress Report", rows, metadata)
    assert isinstance(pdf_bytes, bytes)
    assert len(pdf_bytes) > 0
    assert pdf_bytes.startswith(b"%PDF")


def test_excel_generation():
    rows = [
        {"ID": "STU101", "Name": "Student A", "GPA": "3.8"},
        {"ID": "STU102", "Name": "Student B", "GPA": "3.9"},
    ]
    metadata = {"GeneratedBy": "Admin", "Campus": "Main Campus"}

    excel_bytes = ReportService.build_excel("Academic Progress Report", rows, metadata)
    assert isinstance(excel_bytes, bytes)
    assert len(excel_bytes) > 0
    # ZIP header for Excel .xlsx files (PK\x03\x04)
    assert excel_bytes.startswith(b"PK\x03\x04")
