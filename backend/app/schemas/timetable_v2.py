from pydantic import BaseModel, Field


class TimetableCreateRequest(BaseModel):
    course_offering_id: int
    day_of_week: int = Field(ge=1, le=7)
    start_time: str = Field(min_length=4, max_length=10)
    end_time: str = Field(min_length=4, max_length=10)
    room: str | None = Field(default=None, max_length=100)
    building: str | None = Field(default=None, max_length=150)
    faculty_name: str | None = Field(default=None, max_length=200)


class TimetableResponse(BaseModel):
    id: int
    course_offering_id: int
    day_of_week: int
    start_time: str
    end_time: str
    room: str | None
    building: str | None
    faculty_name: str | None
    is_active: bool


class StudentTimetableResponse(BaseModel):
    id: int
    course_offering_id: int
    course_id: int
    course_code: str
    course_name: str
    day_of_week: int
    start_time: str
    end_time: str
    room: str | None
    building: str | None
    faculty_name: str | None
    section: str | None
    academic_session: str
