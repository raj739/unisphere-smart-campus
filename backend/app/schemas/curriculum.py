from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field


class CurriculumCourseResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    course_id: int
    course_code: str
    course_name: str
    semester_number: int
    source_paper_code: str
    paper_type: str
    theory_credits: int
    practical_credits: int
    total_credits: int
    has_practical: bool
    display_order: int
    weekly_hours: int | None
    max_marks: int | None
    passing_marks: int | None
    elective_group: str | None


class CurriculumSummaryResponse(BaseModel):
    id: int
    catalog_key: str
    programme_id: int
    programme_name: str
    specialization_id: int | None
    specialization_name: str
    academic_session: str | None
    name: str
    version: str
    status: str
    is_demo: bool
    source_name: str | None
    disclaimer: str | None
    semester_count: int
    course_count: int
    total_credits: int
    created_at: datetime
    updated_at: datetime


class CurriculumDetailResponse(CurriculumSummaryResponse):
    courses: list[CurriculumCourseResponse]


class CurriculumStatusUpdateRequest(BaseModel):
    status: str = Field(min_length=4, max_length=30)
