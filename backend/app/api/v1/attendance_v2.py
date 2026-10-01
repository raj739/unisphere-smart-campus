from datetime import date

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_user, require_role
from app.models.attendance_record_v2 import AttendanceRecordV2
from app.models.attendance_session_v2 import AttendanceSessionV2
from app.models.course_offering import CourseOffering
from app.models.student import Student
from app.models.student_enrollment import StudentEnrollment
from app.models.user import User
from app.schemas.attendance_v2 import (
    AttendanceBulkRequest,
    AttendanceRecordCreateRequest,
    AttendanceRecordResponse,
    AttendanceRosterStudentResponse,
    AttendanceSessionCreateRequest,
    AttendanceSessionResponse,
    AttendanceSummaryResponse,
    StudentAttendanceResponse,
)

router = APIRouter(
    prefix="/attendance-v2",
    tags=["Real Attendance"],
)

ALLOWED_STATUSES = {
    "present",
    "absent",
    "late",
    "excused",
}


def get_offering(
    offering_id: int,
    db: Session,
) -> CourseOffering:
    offering = (
        db.query(CourseOffering)
        .filter(CourseOffering.id == offering_id)
        .first()
    )

    if offering is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Course offering not found",
        )

    return offering


def get_session(
    session_id: int,
    db: Session,
) -> AttendanceSessionV2:
    session = (
        db.query(AttendanceSessionV2)
        .filter(AttendanceSessionV2.id == session_id)
        .first()
    )

    if session is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Attendance session not found",
        )

    return session


def get_student(
    student_id: int,
    db: Session,
) -> Student:
    student = (
        db.query(Student)
        .filter(Student.id == student_id)
        .first()
    )

    if student is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Student not found",
        )

    return student


def calculate_summary(
    student: Student,
    offering: CourseOffering,
    db: Session,
):
    session_ids = [
        row.id
        for row in (
            db.query(AttendanceSessionV2.id)
            .filter(
                AttendanceSessionV2.course_offering_id
                == offering.id,
            )
            .all()
        )
    ]

    classes_held = len(session_ids)

    if not session_ids:
        return {
            "classes_held": 0,
            "classes_attended": 0,
            "classes_late": 0,
            "classes_excused": 0,
            "attendance_percentage": 0.0,
        }

    records = (
        db.query(AttendanceRecordV2)
        .filter(
            AttendanceRecordV2.attendance_session_id.in_(
                session_ids
            ),
            AttendanceRecordV2.student_id == student.id,
        )
        .all()
    )

    present = sum(
        1 for record in records
        if record.status == "present"
    )

    late = sum(
        1 for record in records
        if record.status == "late"
    )

    excused = sum(
        1 for record in records
        if record.status == "excused"
    )

    attended = present + late

    percentage = round(
        (attended / classes_held) * 100,
        2,
    )

    return {
        "classes_held": classes_held,
        "classes_attended": attended,
        "classes_late": late,
        "classes_excused": excused,
        "attendance_percentage": percentage,
    }


@router.post(
    "/sessions",
    response_model=AttendanceSessionResponse,
    status_code=status.HTTP_201_CREATED,
)
def create_attendance_session(
    request: AttendanceSessionCreateRequest,
    current_user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    offering = get_offering(
        request.course_offering_id,
        db,
    )

    existing = (
        db.query(AttendanceSessionV2)
        .filter(
            AttendanceSessionV2.course_offering_id
            == offering.id,
            AttendanceSessionV2.session_date
            == request.session_date,
            AttendanceSessionV2.start_time
            == request.start_time,
        )
        .first()
    )

    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Attendance session already exists",
        )

    session = AttendanceSessionV2(
        course_offering_id=offering.id,
        session_date=request.session_date,
        start_time=request.start_time,
        end_time=request.end_time,
        topic=(
            request.topic.strip()
            if request.topic
            else None
        ),
        faculty_name=(
            request.faculty_name.strip()
            if request.faculty_name
            else offering.faculty_name
        ),
        is_locked=False,
    )

    db.add(session)
    db.commit()
    db.refresh(session)

    return session


@router.get(
    "/sessions",
    response_model=list[AttendanceSessionResponse],
)
def get_attendance_sessions(
    course_offering_id: int | None = None,
    current_user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    query = db.query(AttendanceSessionV2)

    if course_offering_id is not None:
        query = query.filter(
            AttendanceSessionV2.course_offering_id
            == course_offering_id
        )

    return (
        query
        .order_by(
            AttendanceSessionV2.session_date.desc(),
            AttendanceSessionV2.start_time.desc(),
        )
        .all()
    )


@router.get(
    "/sessions/{session_id}/roster",
    response_model=list[AttendanceRosterStudentResponse],
)
def get_attendance_roster(
    session_id: int,
    current_user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    session = get_session(session_id, db)
    enrollments = (
        db.query(StudentEnrollment)
        .filter(
            StudentEnrollment.course_offering_id == session.course_offering_id,
            StudentEnrollment.status == "enrolled",
        )
        .all()
    )
    records = {
        record.student_id: record
        for record in db.query(AttendanceRecordV2)
        .filter(AttendanceRecordV2.attendance_session_id == session.id)
        .all()
    }

    roster = []
    for enrollment in enrollments:
        student = enrollment.student
        record = records.get(student.id)
        roster.append(
            AttendanceRosterStudentResponse(
                student_id=student.id,
                uni_id=student.uni_id,
                student_name=student.full_name,
                programme=student.programme,
                status=record.status if record else None,
                remarks=record.remarks if record else None,
            )
        )

    return sorted(roster, key=lambda item: item.student_name.lower())


@router.post(
    "/sessions/{session_id}/records",
    response_model=AttendanceRecordResponse,
    status_code=status.HTTP_201_CREATED,
)
def record_attendance(
    session_id: int,
    request: AttendanceRecordCreateRequest,
    current_user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    session = get_session(session_id, db)

    if session.is_locked:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Attendance session is locked",
        )

    if request.status.strip().lower() not in ALLOWED_STATUSES:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=(
                "Invalid attendance status. Allowed: "
                + ", ".join(sorted(ALLOWED_STATUSES))
            ),
        )

    student = get_student(
        request.student_id,
        db,
    )

    enrollment = (
        db.query(StudentEnrollment)
        .filter(
            StudentEnrollment.student_id == student.id,
            StudentEnrollment.course_offering_id
            == session.course_offering_id,
            StudentEnrollment.status == "enrolled",
        )
        .first()
    )

    if enrollment is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Student is not enrolled in this course",
        )

    existing = (
        db.query(AttendanceRecordV2)
        .filter(
            AttendanceRecordV2.attendance_session_id
            == session.id,
            AttendanceRecordV2.student_id
            == student.id,
        )
        .first()
    )

    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Attendance already recorded for this student",
        )

    record = AttendanceRecordV2(
        attendance_session_id=session.id,
        student_id=student.id,
        status=request.status.strip().lower(),
        remarks=(
            request.remarks.strip()
            if request.remarks
            else None
        ),
    )

    db.add(record)
    db.commit()
    db.refresh(record)

    return record


@router.post(
    "/sessions/{session_id}/bulk",
    response_model=list[AttendanceRecordResponse],
)
def bulk_record_attendance(
    session_id: int,
    request: AttendanceBulkRequest,
    current_user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    session = get_session(session_id, db)

    if session.is_locked:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Attendance session is locked",
        )

    created_records = []

    for item in request.records:
        attendance_status = item.status.strip().lower()

        if attendance_status not in ALLOWED_STATUSES:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Invalid attendance status: {item.status}",
            )

        student = get_student(
            item.student_id,
            db,
        )

        enrollment = (
            db.query(StudentEnrollment)
            .filter(
                StudentEnrollment.student_id == student.id,
                StudentEnrollment.course_offering_id
                == session.course_offering_id,
                StudentEnrollment.status == "enrolled",
            )
            .first()
        )

        if enrollment is None:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=(
                    f"Student {student.id} is not enrolled "
                    "in this course"
                ),
            )

        existing = (
            db.query(AttendanceRecordV2)
            .filter(
                AttendanceRecordV2.attendance_session_id
                == session.id,
                AttendanceRecordV2.student_id
                == student.id,
            )
            .first()
        )

        if existing:
            existing.status = attendance_status
            existing.remarks = (
                item.remarks.strip()
                if item.remarks
                else None
            )
            created_records.append(existing)
            continue

        record = AttendanceRecordV2(
            attendance_session_id=session.id,
            student_id=student.id,
            status=attendance_status,
            remarks=(
                item.remarks.strip()
                if item.remarks
                else None
            ),
        )

        db.add(record)
        created_records.append(record)

    db.commit()

    for record in created_records:
        db.refresh(record)

    return created_records


@router.post(
    "/sessions/{session_id}/lock",
)
def lock_attendance_session(
    session_id: int,
    current_user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    session = get_session(session_id, db)

    session.is_locked = True

    db.commit()

    return {
        "message": "Attendance session locked",
        "session_id": session.id,
    }


@router.get(
    "/me",
    response_model=list[StudentAttendanceResponse],
)
def get_my_attendance(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    student = (
        db.query(Student)
        .filter(Student.user_id == current_user.id)
        .first()
    )

    if student is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Student profile not found",
        )

    enrollments = (
        db.query(StudentEnrollment)
        .filter(
            StudentEnrollment.student_id == student.id,
            StudentEnrollment.status == "enrolled",
        )
        .all()
    )

    result = []

    for enrollment in enrollments:
        offering = enrollment.course_offering
        summary = calculate_summary(
            student,
            offering,
            db,
        )

        result.append(
            StudentAttendanceResponse(
                course_offering_id=offering.id,
                course_id=offering.course_id,
                course_code=offering.course.code,
                course_name=offering.course.name,
                academic_session=offering.academic_session,
                section=offering.section,
                classes_held=summary["classes_held"],
                classes_attended=summary["classes_attended"],
                classes_late=summary["classes_late"],
                classes_excused=summary["classes_excused"],
                attendance_percentage=summary[
                    "attendance_percentage"
                ],
                status=(
                    "critical"
                    if summary["attendance_percentage"] < 60
                    else "warning"
                    if summary["attendance_percentage"] < 75
                    else "good"
                ),
            )
        )

    return result


@router.get(
    "/students/{student_id}",
    response_model=list[StudentAttendanceResponse],
)
def get_student_attendance(
    student_id: int,
    current_user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    student = get_student(
        student_id,
        db,
    )

    enrollments = (
        db.query(StudentEnrollment)
        .filter(
            StudentEnrollment.student_id == student.id,
            StudentEnrollment.status == "enrolled",
        )
        .all()
    )

    result = []

    for enrollment in enrollments:
        offering = enrollment.course_offering
        summary = calculate_summary(
            student,
            offering,
            db,
        )

        result.append(
            StudentAttendanceResponse(
                course_offering_id=offering.id,
                course_id=offering.course_id,
                course_code=offering.course.code,
                course_name=offering.course.name,
                academic_session=offering.academic_session,
                section=offering.section,
                classes_held=summary["classes_held"],
                classes_attended=summary["classes_attended"],
                classes_late=summary["classes_late"],
                classes_excused=summary["classes_excused"],
                attendance_percentage=summary[
                    "attendance_percentage"
                ],
                status=(
                    "critical"
                    if summary["attendance_percentage"] < 60
                    else "warning"
                    if summary["attendance_percentage"] < 75
                    else "good"
                ),
            )
        )

    return result
