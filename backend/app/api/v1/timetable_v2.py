from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_user, require_role
from app.models.course_offering import CourseOffering
from app.models.student import Student
from app.models.student_enrollment import StudentEnrollment
from app.models.timetable_entry_v2 import TimetableEntryV2
from app.models.user import User
from app.schemas.timetable_v2 import (
    StudentTimetableResponse,
    TimetableCreateRequest,
    TimetableResponse,
)

router = APIRouter(
    prefix="/timetable-v2",
    tags=["Timetable"],
)


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


@router.post(
    "/entries",
    response_model=TimetableResponse,
    status_code=status.HTTP_201_CREATED,
)
def create_timetable_entry(
    request: TimetableCreateRequest,
    current_user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    offering = get_offering(
        request.course_offering_id,
        db,
    )

    if request.start_time >= request.end_time:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="End time must be after start time",
        )

    existing = (
        db.query(TimetableEntryV2)
        .filter(
            TimetableEntryV2.course_offering_id
            == offering.id,
            TimetableEntryV2.day_of_week
            == request.day_of_week,
            TimetableEntryV2.start_time
            == request.start_time,
        )
        .first()
    )

    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="A timetable entry already exists for this course and time",
        )

    entry = TimetableEntryV2(
        course_offering_id=offering.id,
        day_of_week=request.day_of_week,
        start_time=request.start_time,
        end_time=request.end_time,
        room=request.room.strip() if request.room else None,
        building=(
            request.building.strip()
            if request.building
            else None
        ),
        faculty_name=(
            request.faculty_name.strip()
            if request.faculty_name
            else offering.faculty_name
        ),
        is_active=True,
    )

    db.add(entry)
    db.commit()
    db.refresh(entry)

    return entry


@router.get(
    "/entries",
    response_model=list[TimetableResponse],
)
def get_timetable_entries(
    current_user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    return (
        db.query(TimetableEntryV2)
        .filter(TimetableEntryV2.is_active.is_(True))
        .order_by(
            TimetableEntryV2.day_of_week.asc(),
            TimetableEntryV2.start_time.asc(),
        )
        .all()
    )


@router.delete(
    "/entries/{entry_id}",
)
def delete_timetable_entry(
    entry_id: int,
    current_user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    entry = (
        db.query(TimetableEntryV2)
        .filter(TimetableEntryV2.id == entry_id)
        .first()
    )

    if entry is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Timetable entry not found",
        )

    entry.is_active = False

    db.commit()

    return {
        "message": "Timetable entry deactivated",
        "entry_id": entry.id,
    }


@router.get(
    "/me",
    response_model=list[StudentTimetableResponse],
)
def get_my_timetable(
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

    offering_ids = [
        enrollment.course_offering_id
        for enrollment in enrollments
    ]

    if not offering_ids:
        return []

    entries = (
        db.query(TimetableEntryV2)
        .filter(
            TimetableEntryV2.course_offering_id.in_(offering_ids),
            TimetableEntryV2.is_active.is_(True),
        )
        .order_by(
            TimetableEntryV2.day_of_week.asc(),
            TimetableEntryV2.start_time.asc(),
        )
        .all()
    )

    result = []

    for entry in entries:
        offering = entry.course_offering

        result.append(
            StudentTimetableResponse(
                id=entry.id,
                course_offering_id=offering.id,
                course_id=offering.course_id,
                course_code=offering.course.code,
                course_name=offering.course.name,
                day_of_week=entry.day_of_week,
                start_time=entry.start_time,
                end_time=entry.end_time,
                room=entry.room,
                building=entry.building,
                faculty_name=entry.faculty_name,
                section=offering.section,
                academic_session=offering.academic_session,
            )
        )

    return result


@router.get(
    "/students/{student_id}",
    response_model=list[StudentTimetableResponse],
)
def get_student_timetable(
    student_id: int,
    current_user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
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

    enrollments = (
        db.query(StudentEnrollment)
        .filter(
            StudentEnrollment.student_id == student.id,
            StudentEnrollment.status == "enrolled",
        )
        .all()
    )

    offering_ids = [
        enrollment.course_offering_id
        for enrollment in enrollments
    ]

    if not offering_ids:
        return []

    entries = (
        db.query(TimetableEntryV2)
        .filter(
            TimetableEntryV2.course_offering_id.in_(offering_ids),
            TimetableEntryV2.is_active.is_(True),
        )
        .order_by(
            TimetableEntryV2.day_of_week.asc(),
            TimetableEntryV2.start_time.asc(),
        )
        .all()
    )

    result = []

    for entry in entries:
        offering = entry.course_offering

        result.append(
            StudentTimetableResponse(
                id=entry.id,
                course_offering_id=offering.id,
                course_id=offering.course_id,
                course_code=offering.course.code,
                course_name=offering.course.name,
                day_of_week=entry.day_of_week,
                start_time=entry.start_time,
                end_time=entry.end_time,
                room=entry.room,
                building=entry.building,
                faculty_name=entry.faculty_name,
                section=offering.section,
                academic_session=offering.academic_session,
            )
        )

    return result
