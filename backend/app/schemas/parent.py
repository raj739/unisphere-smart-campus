from pydantic import BaseModel


class ParentStudentResponse(BaseModel):
    uni_id: str
    full_name: str
    programme: str
    current_semester: int
    academic_session: str | None


class ParentAcademicResponse(BaseModel):
    cgpa: float
    average_attendance: float
    total_courses: int
    academic_status: str


class ParentFeeResponse(BaseModel):
    total_amount: float
    paid_amount: float
    outstanding_amount: float
    due_date: str | None
    status: str


class ParentAlertResponse(BaseModel):
    type: str
    title: str
    message: str
    priority: str


class ParentOverviewResponse(BaseModel):
    student: ParentStudentResponse
    academic: ParentAcademicResponse
    fees: ParentFeeResponse
    alerts: list[ParentAlertResponse]
