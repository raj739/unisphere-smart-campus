from datetime import datetime

from pydantic import BaseModel, Field


class ExaminationCreateRequest(BaseModel):
    name: str = Field(min_length=3, max_length=250)
    exam_type: str = Field(default="semester", min_length=2, max_length=50)
    academic_session: str = Field(min_length=4, max_length=50)
    semester_id: int
    start_date: str | None = Field(default=None, max_length=20)
    end_date: str | None = Field(default=None, max_length=20)
    registration_start: str | None = Field(default=None, max_length=20)
    registration_end: str | None = Field(default=None, max_length=20)


class ExaminationResponse(BaseModel):
    id: int
    name: str
    exam_type: str
    academic_session: str
    semester_id: int
    start_date: str | None
    end_date: str | None
    registration_start: str | None
    registration_end: str | None
    is_registration_open: bool
    is_locked: bool


class ExaminationScheduleCreateRequest(BaseModel):
    examination_id: int
    course_id: int
    exam_date: str = Field(min_length=4, max_length=20)
    start_time: str = Field(min_length=3, max_length=10)
    end_time: str = Field(min_length=3, max_length=10)
    room: str | None = Field(default=None, max_length=100)
    building: str | None = Field(default=None, max_length=150)
    max_marks: int = Field(default=100, ge=1, le=1000)
    passing_marks: int = Field(default=40, ge=0, le=1000)


class ExaminationScheduleResponse(BaseModel):
    id: int
    examination_id: int
    course_id: int
    exam_date: str
    start_time: str
    end_time: str
    room: str | None
    building: str | None
    max_marks: int
    passing_marks: int
    is_active: bool


class ExaminationRegistrationResponse(BaseModel):
    id: int
    examination_id: int
    student_id: int
    registration_number: str
    status: str
    registered_at: datetime
    approved_at: datetime | None


class ExaminationRegistrationPaperResponse(BaseModel):
    id: int
    registration_id: int
    schedule_id: int
    status: str


class ExaminationRegistrationRequest(BaseModel):
    examination_id: int
    schedule_ids: list[int] = Field(min_length=1)


class ExaminationAdminRegistrationRequest(ExaminationRegistrationRequest):
    student_id: int


class ExaminationApprovalRequest(BaseModel):
    status: str = Field(min_length=2, max_length=50)


class ExaminationLockRequest(BaseModel):
    locked: bool


class ExaminationStudentResponse(BaseModel):
    examination_id: int
    name: str
    exam_type: str
    academic_session: str
    semester_id: int
    start_date: str | None
    end_date: str | None
    registration_status: str | None
    registration_number: str | None
    papers: list[ExaminationScheduleResponse]
