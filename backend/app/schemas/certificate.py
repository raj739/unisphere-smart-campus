from datetime import datetime

from pydantic import BaseModel, Field


class CertificateRequestCreate(BaseModel):
    certificate_type: str = Field(min_length=2, max_length=100)
    purpose: str = Field(min_length=5, max_length=2000)
    delivery_mode: str = Field(default="digital", max_length=30)


class CertificateReviewRequest(BaseModel):
    action: str = Field(min_length=2, max_length=30)
    remarks: str | None = Field(default=None, max_length=2000)


class CertificateRequestResponse(BaseModel):
    id: int
    request_number: str
    student_id: int
    certificate_type: str
    certificate_type_label: str
    purpose: str
    delivery_mode: str
    status: str
    requested_at: datetime
    reviewed_at: datetime | None
    review_remarks: str | None
    rejection_reason: str | None
    certificate_id: int | None
    student_name: str
    student_uni_id: str
    student_programme: str
    issued_certificate_number: str | None = None


class CertificateResponse(BaseModel):
    id: int
    certificate_id: str
    certificate_type: str
    certificate_type_label: str
    title: str
    issue_date: str
    status: str
    verification_url: str
    student_name: str
    student_uni_id: str
    student_programme: str


class CertificateVerifyResponse(BaseModel):
    valid: bool
    certificate_id: str
    certificate_type: str
    certificate_type_label: str
    title: str
    issue_date: str
    status: str
    student_name: str
    student_uni_id: str
    student_programme: str
