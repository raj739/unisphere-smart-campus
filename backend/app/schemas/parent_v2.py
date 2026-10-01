from datetime import datetime
from pydantic import BaseModel, Field


class ParentProfileCreateRequest(BaseModel):
    full_name: str = Field(min_length=2, max_length=200)
    phone: str | None = Field(default=None, max_length=30)
    relationship_type: str | None = Field(default=None, max_length=50)


class ParentProfileResponse(BaseModel):
    id: int
    user_id: int
    full_name: str
    phone: str | None
    relationship_type: str | None
    is_active: bool


class ParentStudentLinkCreateRequest(BaseModel):
    parent_user_id: int
    student_id: int
    relationship_type: str | None = Field(default=None, max_length=50)
    is_primary: bool = False


class ParentStudentLinkResponse(BaseModel):
    id: int
    parent_user_id: int
    student_id: int
    relationship_type: str | None
    is_primary: bool
    is_active: bool
    linked_at: datetime


class ParentAccountCreateRequest(BaseModel):
    full_name: str = Field(min_length=2, max_length=200)
    email: str = Field(min_length=5, max_length=255)
    password: str = Field(min_length=8, max_length=128)
    phone: str | None = Field(default=None, max_length=30)
    relationship_type: str = Field(min_length=2, max_length=50)
    student_id: int
    is_primary: bool = True


class ParentStudentSummary(BaseModel):
    student_id: int
    uni_id: str
    full_name: str
    programme: str
    current_semester: int
    academic_session: str | None
    enrollment_number: str | None
    university_id: str | None


class ParentAttendanceSummary(BaseModel):
    student_id: int
    overall_percentage: float
    total_classes: int
    attended_classes: int
    status: str


class ParentFeeSummary(BaseModel):
    student_id: int
    total_amount: float
    paid_amount: float
    outstanding_amount: float
    status: str


class ParentExamSummary(BaseModel):
    student_id: int
    registrations: int
    approved: int
    pending: int


class ParentDashboardResponse(BaseModel):
    student: ParentStudentSummary
    attendance: ParentAttendanceSummary
    fees: ParentFeeSummary
    examinations: ParentExamSummary
