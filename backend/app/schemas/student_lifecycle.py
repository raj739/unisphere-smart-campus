from datetime import datetime

from pydantic import BaseModel, Field


class StudentLifecycleResponse(BaseModel):
    student_id: int
    uni_id: str
    student_name: str
    current_status: str
    admission_date: datetime | None
    graduation_date: datetime | None
    alumni_date: datetime | None
    admission_reference: str | None
    notes: str | None
    updated_at: datetime


class StudentLifecycleUpdateRequest(BaseModel):
    status: str = Field(
        min_length=2,
        max_length=50,
    )
    reason: str | None = Field(
        default=None,
        max_length=1000,
    )
    admission_reference: str | None = Field(
        default=None,
        max_length=150,
    )
    notes: str | None = Field(
        default=None,
        max_length=5000,
    )


class StudentLifecycleEventResponse(BaseModel):
    id: int
    student_id: int
    from_status: str | None
    to_status: str
    reason: str | None
    changed_by_user_id: int
    created_at: datetime
