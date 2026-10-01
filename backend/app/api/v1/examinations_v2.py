from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_user, require_role
from app.models.course import Course
from app.models.examination_v2 import ExaminationV2
from app.models.examination_schedule_v2 import ExaminationScheduleV2
from app.models.examination_registration_v2 import ExaminationRegistrationV2
from app.models.examination_registration_paper_v2 import ExaminationRegistrationPaperV2
from app.models.semester import Semester
from app.models.student import Student
from app.models.student_enrollment import StudentEnrollment
from app.models.course_offering import CourseOffering
from app.models.user import User
from app.schemas.examination_v2 import (
    ExaminationCreateRequest,
    ExaminationResponse,
    ExaminationScheduleCreateRequest,
    ExaminationScheduleResponse,
    ExaminationRegistrationRequest,
    ExaminationAdminRegistrationRequest,
    ExaminationRegistrationResponse,
    ExaminationRegistrationPaperResponse,
    ExaminationApprovalRequest,
    ExaminationLockRequest,
    ExaminationStudentResponse,
)

router = APIRouter(
    prefix="/examinations-v2",
    tags=["Examinations"],
)


def get_exam(examination_id: int, db: Session) -> ExaminationV2:
    exam = (
        db.query(ExaminationV2)
        .filter(ExaminationV2.id == examination_id)
        .first()
    )

    if exam is None:
        raise HTTPException(
            status_code=404,
            detail="Examination not found",
        )

    return exam


def get_student_for_user(user: User, db: Session) -> Student:
    student = (
        db.query(Student)
        .filter(Student.user_id == user.id)
        .first()
    )

    if student is None:
        raise HTTPException(
            status_code=404,
            detail="Student profile not found",
        )

    return student


def generate_registration_number(examination_id: int, student_id: int) -> str:
    return f"EXAM-{examination_id:04d}-{student_id:06d}"


@router.post(
    "",
    response_model=ExaminationResponse,
    dependencies=[Depends(require_role("admin"))],
)
def create_examination(
    payload: ExaminationCreateRequest,
    db: Session = Depends(get_db),
):
    semester = (
        db.query(Semester)
        .filter(Semester.id == payload.semester_id)
        .first()
    )

    if semester is None:
        raise HTTPException(
            status_code=404,
            detail="Semester not found",
        )

    exam = ExaminationV2(
        name=payload.name,
        exam_type=payload.exam_type,
        academic_session=payload.academic_session,
        semester_id=payload.semester_id,
        start_date=payload.start_date,
        end_date=payload.end_date,
        registration_start=payload.registration_start,
        registration_end=payload.registration_end,
        is_registration_open=True,
        is_locked=False,
    )

    db.add(exam)
    db.commit()
    db.refresh(exam)

    return exam


@router.get(
    "",
    response_model=list[ExaminationResponse],
    dependencies=[Depends(require_role("admin"))],
)
def list_examinations(
    db: Session = Depends(get_db),
):
    return (
        db.query(ExaminationV2)
        .order_by(ExaminationV2.id.desc())
        .all()
    )


@router.get(
    "/me",
    response_model=list[ExaminationStudentResponse],
)
def my_examinations(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    student = get_student_for_user(current_user, db)

    registrations = (
        db.query(ExaminationRegistrationV2)
        .filter(
            ExaminationRegistrationV2.student_id == student.id
        )
        .order_by(ExaminationRegistrationV2.id.desc())
        .all()
    )

    result = []

    for registration in registrations:
        exam = registration.examination

        papers = (
            db.query(ExaminationRegistrationPaperV2)
            .filter(
                ExaminationRegistrationPaperV2.registration_id
                == registration.id
            )
            .all()
        )

        schedules = []

        for paper in papers:
            schedule = paper.schedule

            if schedule is not None and schedule.is_active:
                schedules.append(schedule)

        result.append(
            {
                "examination_id": exam.id,
                "name": exam.name,
                "exam_type": exam.exam_type,
                "academic_session": exam.academic_session,
                "semester_id": exam.semester_id,
                "start_date": exam.start_date,
                "end_date": exam.end_date,
                "registration_status": registration.status,
                "registration_number": registration.registration_number,
                "papers": schedules,
            }
        )

    return result


@router.post(
    "/schedules",
    response_model=ExaminationScheduleResponse,
    dependencies=[Depends(require_role("admin"))],
)
def create_schedule(
    payload: ExaminationScheduleCreateRequest,
    db: Session = Depends(get_db),
):
    exam = get_exam(payload.examination_id, db)

    if exam.is_locked:
        raise HTTPException(
            status_code=409,
            detail="Examination is locked",
        )

    course = (
        db.query(Course)
        .filter(Course.id == payload.course_id)
        .first()
    )

    if course is None:
        raise HTTPException(
            status_code=404,
            detail="Course not found",
        )

    if payload.passing_marks > payload.max_marks:
        raise HTTPException(
            status_code=400,
            detail="Passing marks cannot exceed maximum marks",
        )

    schedule = ExaminationScheduleV2(
        examination_id=exam.id,
        course_id=course.id,
        exam_date=payload.exam_date,
        start_time=payload.start_time,
        end_time=payload.end_time,
        room=payload.room,
        building=payload.building,
        max_marks=payload.max_marks,
        passing_marks=payload.passing_marks,
        is_active=True,
    )

    db.add(schedule)
    db.commit()
    db.refresh(schedule)

    return schedule


@router.get(
    "/{examination_id}/schedules",
    response_model=list[ExaminationScheduleResponse],
)
def get_schedules(
    examination_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    get_exam(examination_id, db)

    schedules = (
        db.query(ExaminationScheduleV2)
        .filter(
            ExaminationScheduleV2.examination_id == examination_id,
            ExaminationScheduleV2.is_active.is_(True),
        )
        .order_by(
            ExaminationScheduleV2.exam_date,
            ExaminationScheduleV2.start_time,
        )
        .all()
    )

    return schedules


@router.post(
    "/register",
    response_model=ExaminationRegistrationResponse,
)
def register_for_examination(
    payload: ExaminationRegistrationRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    student = get_student_for_user(current_user, db)
    exam = get_exam(payload.examination_id, db)

    if exam.is_locked:
        raise HTTPException(
            status_code=409,
            detail="Examination registration is locked",
        )

    if not exam.is_registration_open:
        raise HTTPException(
            status_code=409,
            detail="Examination registration is closed",
        )

    existing = (
        db.query(ExaminationRegistrationV2)
        .filter(
            ExaminationRegistrationV2.examination_id == exam.id,
            ExaminationRegistrationV2.student_id == student.id,
        )
        .first()
    )

    if existing is not None:
        raise HTTPException(
            status_code=409,
            detail="Student is already registered for this examination",
        )

    unique_schedule_ids = list(set(payload.schedule_ids))

    schedules = (
        db.query(ExaminationScheduleV2)
        .filter(
            ExaminationScheduleV2.id.in_(unique_schedule_ids),
            ExaminationScheduleV2.examination_id == exam.id,
            ExaminationScheduleV2.is_active.is_(True),
        )
        .all()
    )

    if len(schedules) != len(unique_schedule_ids):
        raise HTTPException(
            status_code=400,
            detail="One or more examination papers are invalid",
        )

    for schedule in schedules:
        enrolled = (
            db.query(StudentEnrollment)
            .filter(
                StudentEnrollment.student_id == student.id,
                StudentEnrollment.status == "enrolled",
                StudentEnrollment.course_offering.has(
                    course_id=schedule.course_id
                ),
            )
            .first()
        )

        if enrolled is None:
            raise HTTPException(
                status_code=400,
                detail=f"Student is not enrolled in course {schedule.course_id}",
            )

    registration = ExaminationRegistrationV2(
        examination_id=exam.id,
        student_id=student.id,
        registration_number=generate_registration_number(
            exam.id,
            student.id,
        ),
        status="registered",
    )

    db.add(registration)
    db.flush()

    for schedule in schedules:
        paper = ExaminationRegistrationPaperV2(
            registration_id=registration.id,
            schedule_id=schedule.id,
            status="registered",
        )
        db.add(paper)

    db.commit()
    db.refresh(registration)

    return registration


@router.post(
    "/admin/register",
    response_model=ExaminationRegistrationResponse,
)
def register_student_for_examination(
    payload: ExaminationAdminRegistrationRequest,
    current_user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    student = (
        db.query(Student)
        .filter(Student.id == payload.student_id)
        .first()
    )

    if student is None:
        raise HTTPException(status_code=404, detail="Student not found")

    exam = get_exam(payload.examination_id, db)

    existing = (
        db.query(ExaminationRegistrationV2)
        .filter(
            ExaminationRegistrationV2.examination_id == exam.id,
            ExaminationRegistrationV2.student_id == student.id,
        )
        .first()
    )

    if existing is not None:
        raise HTTPException(
            status_code=409,
            detail="Student is already registered for this examination",
        )

    unique_schedule_ids = list(set(payload.schedule_ids))
    schedules = (
        db.query(ExaminationScheduleV2)
        .filter(
            ExaminationScheduleV2.id.in_(unique_schedule_ids),
            ExaminationScheduleV2.examination_id == exam.id,
            ExaminationScheduleV2.is_active.is_(True),
        )
        .all()
    )

    if len(schedules) != len(unique_schedule_ids):
        raise HTTPException(
            status_code=400,
            detail="One or more examination papers are invalid",
        )

    for schedule in schedules:
        enrolled = (
            db.query(StudentEnrollment)
            .filter(
                StudentEnrollment.student_id == student.id,
                StudentEnrollment.status == "enrolled",
                StudentEnrollment.course_offering.has(
                    course_id=schedule.course_id
                ),
            )
            .first()
        )

        if enrolled is None:
            raise HTTPException(
                status_code=400,
                detail=f"Student is not enrolled in course {schedule.course_id}",
            )

    registration = ExaminationRegistrationV2(
        examination_id=exam.id,
        student_id=student.id,
        registration_number=generate_registration_number(
            exam.id,
            student.id,
        ),
        status="approved",
        approved_at=datetime.now(timezone.utc),
        approved_by_user_id=current_user.id,
    )

    db.add(registration)
    db.flush()

    for schedule in schedules:
        db.add(
            ExaminationRegistrationPaperV2(
                registration_id=registration.id,
                schedule_id=schedule.id,
                status="registered",
            )
        )

    db.commit()
    db.refresh(registration)
    return registration


@router.get(
    "/registrations",
    response_model=list[ExaminationRegistrationResponse],
    dependencies=[Depends(require_role("admin"))],
)
def list_registrations(
    examination_id: int | None = None,
    db: Session = Depends(get_db),
):
    query = db.query(ExaminationRegistrationV2)

    if examination_id is not None:
        query = query.filter(
            ExaminationRegistrationV2.examination_id
            == examination_id
        )

    return query.order_by(
        ExaminationRegistrationV2.id.desc()
    ).all()


@router.patch(
    "/registrations/{registration_id}/status",
    response_model=ExaminationRegistrationResponse,
    dependencies=[Depends(require_role("admin"))],
)
def update_registration_status(
    registration_id: int,
    payload: ExaminationApprovalRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    allowed = {
        "registered",
        "approved",
        "rejected",
        "cancelled",
    }

    if payload.status not in allowed:
        raise HTTPException(
            status_code=400,
            detail="Invalid examination registration status",
        )

    registration = (
        db.query(ExaminationRegistrationV2)
        .filter(
            ExaminationRegistrationV2.id == registration_id
        )
        .first()
    )

    if registration is None:
        raise HTTPException(
            status_code=404,
            detail="Examination registration not found",
        )

    registration.status = payload.status

    if payload.status == "approved":
        registration.approved_at = datetime.now(timezone.utc)
        registration.approved_by_user_id = current_user.id

    db.commit()
    db.refresh(registration)

    return registration


@router.get(
    "/registrations/{registration_id}/papers",
    response_model=list[ExaminationRegistrationPaperResponse],
)
def registration_papers(
    registration_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    registration = (
        db.query(ExaminationRegistrationV2)
        .filter(
            ExaminationRegistrationV2.id == registration_id
        )
        .first()
    )

    if registration is None:
        raise HTTPException(
            status_code=404,
            detail="Examination registration not found",
        )

    student = get_student_for_user(current_user, db)

    if (
        current_user.role != "admin"
        and registration.student_id != student.id
    ):
        raise HTTPException(
            status_code=403,
            detail="You cannot access this registration",
        )

    return (
        db.query(ExaminationRegistrationPaperV2)
        .filter(
            ExaminationRegistrationPaperV2.registration_id
            == registration_id
        )
        .all()
    )


@router.patch(
    "/{examination_id}/registration-lock",
    response_model=ExaminationResponse,
    dependencies=[Depends(require_role("admin"))],
)
def update_registration_lock(
    examination_id: int,
    payload: ExaminationLockRequest,
    db: Session = Depends(get_db),
):
    exam = get_exam(examination_id, db)

    if exam.is_locked and not payload.locked:
        raise HTTPException(
            status_code=409,
            detail="Locked examination cannot be reopened",
        )

    exam.is_registration_open = not payload.locked

    db.commit()
    db.refresh(exam)

    return exam


@router.patch(
    "/{examination_id}/lock",
    response_model=ExaminationResponse,
    dependencies=[Depends(require_role("admin"))],
)
def lock_examination(
    examination_id: int,
    payload: ExaminationLockRequest,
    db: Session = Depends(get_db),
):
    exam = get_exam(examination_id, db)

    if exam.is_locked and not payload.locked:
        raise HTTPException(
            status_code=409,
            detail="Locked examination cannot be reopened",
        )

    exam.is_locked = payload.locked

    if payload.locked:
        exam.is_registration_open = False

    db.commit()
    db.refresh(exam)

    return exam

