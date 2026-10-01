from pydantic import BaseModel, Field


class DocumentCreateRequest(BaseModel):
    student_id: int
    document_type: str = Field(
        min_length=2,
        max_length=50,
    )
    title: str = Field(
        min_length=2,
        max_length=250,
    )
    issue_date: str = Field(
        min_length=4,
        max_length=20,
    )
    valid_until: str | None = Field(
        default=None,
        max_length=20,
    )


class DocumentResponse(BaseModel):
    id: int
    student_id: int
    document_type: str
    document_number: str
    title: str
    issue_date: str
    valid_until: str | None
    status: str
    file_path: str | None
    verification_token: str
    qr_payload: str | None


class DocumentStatusRequest(BaseModel):
    status: str = Field(
        min_length=2,
        max_length=50,
    )


class DocumentVerifyResponse(BaseModel):
    valid: bool
    document_number: str
    document_type: str
    title: str
    student_name: str
    uni_id: str
    programme: str
    issue_date: str
    valid_until: str | None
    status: str


class DocumentEventResponse(BaseModel):
    id: int
    document_id: int
    event_type: str
    performed_by_user_id: int | None
    details: str | None
    created_at: str


class StudentDocumentResponse(BaseModel):
    id: int
    document_type: str
    document_number: str
    title: str
    issue_date: str
    valid_until: str | None
    status: str
    verification_token: str


class AdminDocumentResponse(DocumentResponse):
    student_name: str
    uni_id: str
    programme: str
