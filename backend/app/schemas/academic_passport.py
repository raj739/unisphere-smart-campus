from datetime import datetime

from pydantic import BaseModel, ConfigDict


class AcademicPassportResponse(BaseModel):
    id: int
    passport_number: str
    verification_token: str
    full_name: str
    uni_id: str
    programme: str | None
    current_semester: int | None
    academic_session: str | None
    status: str
    summary: str
    is_verified: bool
    generated_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


class AcademicPassportVerifyResponse(BaseModel):
    valid: bool
    passport_number: str | None = None
    full_name: str | None = None
    uni_id: str | None = None
    programme: str | None = None
    status: str | None = None
    verified_at: datetime | None = None
