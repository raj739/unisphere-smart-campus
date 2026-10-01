from datetime import date

from pydantic import BaseModel, Field


class AttendanceSessionCreateRequest(BaseModel):
    course_offering_id: int
    session_date: date
    start_time: str | None = Field(
        default=None,
        max_length=10,
    )
    end_time: str | None = Field(
        default=None,
        max_length=10,
    )
    topic: str | None = Field(
        default=None,
        max_length=300,
    )
    faculty_name: str | None = Field(
        default=None,
        max_length=200,
    )


class AttendanceSessionResponse(BaseModel):
    id: int
    course_offering_id: int
    session_date: date
    start_time: str | None
    end_time: str | None
    topic: str | None
    faculty_name: str | None
    is_locked: bool


class AttendanceRecordCreateRequest(BaseModel):
    student_id: int
    status: str = Field(
        min_length=2,
        max_length=30,
    )
    remarks: str | None = Field(
        default=None,
        max_length=500,
    )


class AttendanceRecordResponse(BaseModel):
    id: int
    attendance_session_id: int
    student_id: int
    status: str
    remarks: str | None


class AttendanceRosterStudentResponse(BaseModel):
    student_id: int
    uni_id: str
    student_name: str
    programme: str
    status: str | None
    remarks: str | None


class AttendanceBulkRecord(BaseModel):
    student_id: int
    status: str = Field(
        min_length=2,
        max_length=30,
    )
    remarks: str | None = Field(
        default=None,
        max_length=500,
    )


class AttendanceBulkRequest(BaseModel):
    records: list[AttendanceBulkRecord]


class AttendanceSummaryResponse(BaseModel):
    student_id: int
    uni_id: str
    student_name: str
    course_offering_id: int
    course_id: int
    classes_held: int
    classes_attended: int
    classes_late: int
    classes_excused: int
    attendance_percentage: float
    status: str


class StudentAttendanceResponse(BaseModel):
    course_offering_id: int
    course_id: int
    course_code: str
    course_name: str
    academic_session: str
    section: str | None
    classes_held: int
    classes_attended: int
    classes_late: int
    classes_excused: int
    attendance_percentage: float
    status: str
