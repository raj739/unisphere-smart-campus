from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_user, require_role
from app.models.course import Course
from app.models.course_offering import CourseOffering
from app.models.semester import Semester
from app.models.student import Student
from app.models.student_enrollment import StudentEnrollment
from app.models.user import User
from app.schemas.course_enrollment import (
    CourseOfferingCreateRequest,
    CourseOfferingResponse,
    EnrollmentCreateRequest,
    EnrollmentResponse,
    EnrollmentStatusRequest,
    StudentCourseResponse,
)

router = APIRouter(
    prefix="/enrollment",
    tags=["Course & Enrollment"],
)

ALLOWED_ENROLLMENT_STATUSES = {
    "enrolled",
    "completed",
    "dropped",
    "withdrawn",
}


def get_student(student_id: int, db: Session) -> Student:
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
    "/offerings",
    response_model=CourseOfferingResponse,
    status_code=status.HTTP_201_CREATED,
)
def create_course_offering(
    request: CourseOfferingCreateRequest,
    current_user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    course = (
        db.query(Course)
        .filter(Course.id == request.course_id)
        .first()
    )

    if course is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Course not found",
        )

    semester = (
        db.query(Semester)
        .filter(Semester.id == request.semester_id)
        .first()
    )

    if semester is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Semester not found",
        )

    academic_session = request.academic_session.strip()
    section = (
        request.section.strip()
        if request.section
        else None
    )

    existing = (
        db.query(CourseOffering)
        .filter(
            CourseOffering.course_id == request.course_id,
            CourseOffering.semester_id == request.semester_id,
            CourseOffering.academic_session == academic_session,
            CourseOffering.section == section,
        )
        .first()
    )

    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="This course offering already exists",
        )

    offering = CourseOffering(
        course_id=request.course_id,
        semester_id=request.semester_id,
        academic_session=academic_session,
        section=section,
        faculty_name=(
            request.faculty_name.strip()
            if request.faculty_name
            else None
        ),
        capacity=request.capacity,
        is_active=True,
    )

    db.add(offering)
    db.commit()
    db.refresh(offering)

    return offering


@router.get(
    "/offerings",
    response_model=list[CourseOfferingResponse],
)
def get_course_offerings(
    current_user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    return (
        db.query(CourseOffering)
        .order_by(CourseOffering.id.desc())
        .all()
    )


@router.post(
    "/enroll",
    response_model=EnrollmentResponse,
    status_code=status.HTTP_201_CREATED,
)
def enroll_student(
    request: EnrollmentCreateRequest,
    current_user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    student = get_student(request.student_id, db)
    offering = get_offering(request.course_offering_id, db)

    if not offering.is_active:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Course offering is inactive",
        )

    existing = (
        db.query(StudentEnrollment)
        .filter(
            StudentEnrollment.student_id == student.id,
            StudentEnrollment.course_offering_id
            == offering.id,
        )
        .first()
    )

    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Student is already enrolled in this course offering",
        )

    if offering.capacity is not None:
        enrolled_count = (
            db.query(StudentEnrollment)
            .filter(
                StudentEnrollment.course_offering_id == offering.id,
                StudentEnrollment.status == "enrolled",
            )
            .count()
        )

        if enrolled_count >= offering.capacity:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Course offering capacity is full",
            )

    enrollment = StudentEnrollment(
        student_id=student.id,
        course_offering_id=offering.id,
        status="enrolled",
    )

    db.add(enrollment)
    db.commit()
    db.refresh(enrollment)

    return enrollment


@router.patch(
    "/{enrollment_id}/status",
    response_model=EnrollmentResponse,
)
def update_enrollment_status(
    enrollment_id: int,
    request: EnrollmentStatusRequest,
    current_user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    enrollment = (
        db.query(StudentEnrollment)
        .filter(StudentEnrollment.id == enrollment_id)
        .first()
    )

    if enrollment is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Enrollment not found",
        )

    new_status = request.status.strip().lower()

    if new_status not in ALLOWED_ENROLLMENT_STATUSES:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=(
                "Invalid enrollment status. Allowed statuses: "
                + ", ".join(sorted(ALLOWED_ENROLLMENT_STATUSES))
            ),
        )

    enrollment.status = new_status

    if new_status in {"dropped", "withdrawn"}:
        enrollment.dropped_at = datetime.now(timezone.utc)
    else:
        enrollment.dropped_at = None

    db.commit()
    db.refresh(enrollment)

    return enrollment


@router.get(
    "/me",
    response_model=list[StudentCourseResponse],
)
def get_my_courses(
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
        .order_by(StudentEnrollment.id.desc())
        .all()
    )

    result = []

    for enrollment in enrollments:
        offering = enrollment.course_offering

        result.append(
            StudentCourseResponse(
                enrollment_id=enrollment.id,
                student_id=student.id,
                uni_id=student.uni_id,
                student_name=student.full_name,
                course_offering_id=offering.id,
                course_id=offering.course_id,
                course_code=offering.course.code,
                course_name=offering.course.name,
                credits=offering.course.credits,
                semester_id=offering.semester_id,
                academic_session=offering.academic_session,
                section=offering.section,
                faculty_name=offering.faculty_name,
                enrollment_status=enrollment.status,
            )
        )

    return result


@router.get(
    "/students/{student_id}",
    response_model=list[StudentCourseResponse],
)
def get_student_courses(
    student_id: int,
    current_user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    student = get_student(student_id, db)

    enrollments = (
        db.query(StudentEnrollment)
        .filter(StudentEnrollment.student_id == student.id)
        .order_by(StudentEnrollment.id.desc())
        .all()
    )

    result = []

    for enrollment in enrollments:
        offering = enrollment.course_offering

        result.append(
            StudentCourseResponse(
                enrollment_id=enrollment.id,
                student_id=student.id,
                uni_id=student.uni_id,
                student_name=student.full_name,
                course_offering_id=offering.id,
                course_id=offering.course_id,
                course_code=offering.course.code,
                course_name=offering.course.name,
                credits=offering.course.credits,
                semester_id=offering.semester_id,
                academic_session=offering.academic_session,
                section=offering.section,
                faculty_name=offering.faculty_name,
                enrollment_status=enrollment.status,
            )
        )

    return result
