from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_user, require_role
from app.models.student import Student
from app.models.student_lifecycle import StudentLifecycle
from app.models.student_lifecycle_event import StudentLifecycleEvent
from app.models.user import User
from app.schemas.student_lifecycle import (
    StudentLifecycleEventResponse,
    StudentLifecycleResponse,
    StudentLifecycleUpdateRequest,
)

router = APIRouter(
    prefix="/lifecycle",
    tags=["Student Lifecycle"],
)

ALLOWED_STATUSES = {
    "admitted",
    "registered",
    "active",
    "on_leave",
    "suspended",
    "graduated",
    "alumni",
    "withdrawn",
    "transferred",
}


def get_student(uni_id: str, db: Session) -> Student:
    student = (
        db.query(Student)
        .filter(Student.uni_id == uni_id)
        .first()
    )

    if student is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Student not found",
        )

    return student


def get_or_create_lifecycle(
    student: Student,
    db: Session,
) -> StudentLifecycle:
    lifecycle = (
        db.query(StudentLifecycle)
        .filter(StudentLifecycle.student_id == student.id)
        .first()
    )

    if lifecycle is None:
        lifecycle = StudentLifecycle(
            student_id=student.id,
            current_status="active",
        )

        db.add(lifecycle)
        db.flush()

    return lifecycle


def lifecycle_response(
    student: Student,
    lifecycle: StudentLifecycle,
) -> StudentLifecycleResponse:
    return StudentLifecycleResponse(
        student_id=student.id,
        uni_id=student.uni_id,
        student_name=student.full_name,
        current_status=lifecycle.current_status,
        admission_date=lifecycle.admission_date,
        graduation_date=lifecycle.graduation_date,
        alumni_date=lifecycle.alumni_date,
        admission_reference=lifecycle.admission_reference,
        notes=lifecycle.notes,
        updated_at=lifecycle.updated_at,
    )


@router.get(
    "/me",
    response_model=StudentLifecycleResponse,
)
def get_my_lifecycle(
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

    lifecycle = get_or_create_lifecycle(student, db)
    db.commit()
    db.refresh(lifecycle)

    return lifecycle_response(student, lifecycle)


@router.get(
    "/me/history",
    response_model=list[StudentLifecycleEventResponse],
)
def get_my_lifecycle_history(
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

    return (
        db.query(StudentLifecycleEvent)
        .filter(StudentLifecycleEvent.student_id == student.id)
        .order_by(StudentLifecycleEvent.created_at.desc())
        .all()
    )


@router.get(
    "/students/{uni_id}",
    response_model=StudentLifecycleResponse,
)
def get_student_lifecycle(
    uni_id: str,
    current_user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    student = get_student(uni_id, db)
    lifecycle = get_or_create_lifecycle(student, db)

    db.commit()
    db.refresh(lifecycle)

    return lifecycle_response(student, lifecycle)


@router.patch(
    "/students/{uni_id}",
    response_model=StudentLifecycleResponse,
)
def update_student_lifecycle(
    uni_id: str,
    request: StudentLifecycleUpdateRequest,
    current_user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    new_status = request.status.strip().lower()

    if new_status not in ALLOWED_STATUSES:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=(
                "Invalid lifecycle status. Allowed statuses: "
                + ", ".join(sorted(ALLOWED_STATUSES))
            ),
        )

    student = get_student(uni_id, db)
    lifecycle = get_or_create_lifecycle(student, db)

    old_status = lifecycle.current_status

    now = datetime.now(timezone.utc)

    lifecycle.current_status = new_status

    if request.admission_reference is not None:
        lifecycle.admission_reference = (
            request.admission_reference.strip()
        )

    if request.notes is not None:
        lifecycle.notes = request.notes.strip()

    if new_status == "admitted" and lifecycle.admission_date is None:
        lifecycle.admission_date = now

    if new_status == "graduated":
        lifecycle.graduation_date = now

    if new_status == "alumni":
        if lifecycle.graduation_date is None:
            lifecycle.graduation_date = now

        lifecycle.alumni_date = now

    event = StudentLifecycleEvent(
        student_id=student.id,
        from_status=old_status,
        to_status=new_status,
        reason=(
            request.reason.strip()
            if request.reason
            else None
        ),
        changed_by_user_id=current_user.id,
    )

    db.add(event)
    db.commit()
    db.refresh(lifecycle)

    return lifecycle_response(student, lifecycle)


@router.get(
    "/students/{uni_id}/history",
    response_model=list[StudentLifecycleEventResponse],
)
def get_student_lifecycle_history(
    uni_id: str,
    current_user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    student = get_student(uni_id, db)

    return (
        db.query(StudentLifecycleEvent)
        .filter(StudentLifecycleEvent.student_id == student.id)
        .order_by(StudentLifecycleEvent.created_at.desc())
        .all()
    )
