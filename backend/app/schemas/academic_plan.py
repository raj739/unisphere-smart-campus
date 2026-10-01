from pydantic import BaseModel, Field


class AcademicPlanAssignRequest(BaseModel):
    programme_id: int
    specialization_id: int | None = None
    curriculum_id: int
    academic_session_id: int
    current_semester: int = Field(ge=1, le=20)
    section: str = Field(default="A", min_length=1, max_length=50)
    auto_enroll: bool = True
    create_standard_timetable: bool = False
    create_demo_exam_plan: bool = False
    create_fee_invoice: bool = True


class AcademicPlanResponse(BaseModel):
    student_id: int
    student_name: str
    uni_id: str
    programme_id: int
    programme_name: str
    specialization_id: int | None
    specialization_name: str
    curriculum_id: int
    curriculum_name: str
    curriculum_status: str
    is_demo_curriculum: bool
    academic_session_id: int
    academic_session: str
    current_semester: int
    semester_id: int
    section: str
    curriculum_course_count: int
    active_enrollment_count: int
    timetable_entry_count: int
    invoice_count: int
    exam_registration_count: int
    result_count: int
    offerings_created: int = 0
    enrollments_created: int = 0
    enrollments_reactivated: int = 0
    enrollments_archived: int = 0
    timetable_entries_created: int = 0
    invoices_created: int = 0
    exam_schedules_created: int = 0
    exam_registrations_created: int = 0
    courses: list[dict] = []


class ResultPublishRequest(BaseModel):
    course_id: int
    semester_id: int
    marks: float = Field(ge=0, le=100)


class ResultPublishResponse(BaseModel):
    id: int
    student_id: int
    course_id: int
    semester_id: int
    marks: float
    grade: str
    grade_point: float
