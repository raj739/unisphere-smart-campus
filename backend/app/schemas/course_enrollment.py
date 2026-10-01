from datetime import datetime

from pydantic import BaseModel, Field


class CourseOfferingCreateRequest(BaseModel):
    course_id: int
    semester_id: int
    academic_session: str = Field(
        min_length=4,
        max_length=50,
    )
    section: str | None = Field(
        default=None,
        max_length=50,
    )
    faculty_name: str | None = Field(
        default=None,
        max_length=200,
    )
    capacity: int | None = Field(
        default=None,
        ge=1,
        le=10000,
    )


class CourseOfferingResponse(BaseModel):
    id: int
    course_id: int
    semester_id: int
    academic_session: str
    section: str | None
    faculty_name: str | None
    capacity: int | None
    is_active: bool


class EnrollmentCreateRequest(BaseModel):
    student_id: int
    course_offering_id: int


class EnrollmentResponse(BaseModel):
    id: int
    student_id: int
    course_offering_id: int
    status: str
    enrolled_at: datetime
    dropped_at: datetime | None


class EnrollmentStatusRequest(BaseModel):
    status: str = Field(
        min_length=2,
        max_length=50,
    )


class StudentCourseResponse(BaseModel):
    enrollment_id: int
    student_id: int
    uni_id: str
    student_name: str
    course_offering_id: int
    course_id: int
    course_code: str
    course_name: str
    credits: int
    semester_id: int
    academic_session: str
    section: str | None
    faculty_name: str | None
    enrollment_status: str
