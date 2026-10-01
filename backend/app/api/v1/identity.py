from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_user, require_role
from app.models.student import Student
from app.models.student_identifier import StudentIdentifier
from app.models.user import User
from app.schemas.identity import (
    AccountStatusRequest,
    StudentIdentifierCreateRequest,
    StudentIdentifierResponse,
    StudentIdentityResponse,
    StudentIdentityUpdateRequest,
)

router = APIRouter(
    prefix="/identity",
    tags=["Identity Management"],
)


def _get_student_or_404(uni_id: str, db: Session) -> Student:
    student = db.query(Student).filter(Student.uni_id == uni_id).first()

    if student is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Student not found",
        )

    return student


def _identity_response(student: Student) -> StudentIdentityResponse:
    return StudentIdentityResponse(
        student_id=student.id,
        user_id=student.user_id,
        uni_id=student.uni_id,
        full_name=student.full_name,
        email=student.user.email,
        university_id=student.university_id,
        enrollment_number=student.enrollment_number,
        programme=student.programme,
        programme_id=student.programme_id,
        specialization_id=student.specialization_id,
        curriculum_id=student.curriculum_id,
        academic_session_id=student.academic_session_id,
        current_semester=student.current_semester,
        academic_session=student.academic_session,
        department_id=student.department_id,
        role=student.user.role,
        is_active=student.user.is_active,
    )


@router.get("/me", response_model=StudentIdentityResponse)
def get_my_identity(
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

    return _identity_response(student)


@router.get(
    "/students/{uni_id}",
    response_model=StudentIdentityResponse,
)
def get_student_identity(
    uni_id: str,
    current_user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    student = _get_student_or_404(uni_id, db)
    return _identity_response(student)


@router.put(
    "/students/{uni_id}",
    response_model=StudentIdentityResponse,
)
def update_student_identity(
    uni_id: str,
    update: StudentIdentityUpdateRequest,
    current_user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    student = _get_student_or_404(uni_id, db)
    user = student.user

    if update.university_id is not None:
        university_id = update.university_id.strip()

        if university_id != student.university_id:
            existing = (
                db.query(Student)
                .filter(
                    Student.university_id == university_id,
                    Student.id != student.id,
                )
                .first()
            )

            if existing:
                raise HTTPException(
                    status_code=status.HTTP_409_CONFLICT,
                    detail="University ID already exists",
                )

            student.university_id = university_id

    if update.enrollment_number is not None:
        enrollment_number = update.enrollment_number.strip()

        if enrollment_number != student.enrollment_number:
            existing = (
                db.query(Student)
                .filter(
                    Student.enrollment_number == enrollment_number,
                    Student.id != student.id,
                )
                .first()
            )

            if existing:
                raise HTTPException(
                    status_code=status.HTTP_409_CONFLICT,
                    detail="Enrollment number already exists",
                )

            student.enrollment_number = enrollment_number

    if update.full_name is not None:
        student.full_name = update.full_name.strip()

    if update.programme is not None:
        student.programme = update.programme.strip()

    if update.current_semester is not None:
        student.current_semester = update.current_semester

    if update.academic_session is not None:
        student.academic_session = update.academic_session.strip()

    db.commit()
    db.refresh(student)

    return _identity_response(student)


@router.patch(
    "/students/{uni_id}/status",
    response_model=StudentIdentityResponse,
)
def update_account_status(
    uni_id: str,
    request: AccountStatusRequest,
    current_user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    student = _get_student_or_404(uni_id, db)

    student.user.is_active = request.is_active

    db.commit()
    db.refresh(student)

    return _identity_response(student)


@router.get(
    "/students/{uni_id}/identifiers",
    response_model=list[StudentIdentifierResponse],
)
def get_student_identifiers(
    uni_id: str,
    current_user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    student = _get_student_or_404(uni_id, db)

    return (
        db.query(StudentIdentifier)
        .filter(StudentIdentifier.student_id == student.id)
        .order_by(StudentIdentifier.id.asc())
        .all()
    )


@router.post(
    "/students/{uni_id}/identifiers",
    response_model=StudentIdentifierResponse,
    status_code=status.HTTP_201_CREATED,
)
def add_student_identifier(
    uni_id: str,
    request: StudentIdentifierCreateRequest,
    current_user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    student = _get_student_or_404(uni_id, db)

    identifier_type = request.identifier_type.strip().lower()
    identifier_value = request.identifier_value.strip()

    existing = (
        db.query(StudentIdentifier)
        .filter(
            StudentIdentifier.identifier_type == identifier_type,
            StudentIdentifier.identifier_value == identifier_value,
        )
        .first()
    )

    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="This identifier already exists",
        )

    identifier = StudentIdentifier(
        student_id=student.id,
        identifier_type=identifier_type,
        identifier_value=identifier_value,
        issuing_authority=(
            request.issuing_authority.strip()
            if request.issuing_authority
            else None
        ),
        is_verified=request.is_verified,
    )

    db.add(identifier)
    db.commit()
    db.refresh(identifier)

    return identifier


@router.get(
    "/verify/{uni_id}",
    response_model=StudentIdentityResponse,
)
def verify_student_identity(
    uni_id: str,
    db: Session = Depends(get_db),
):
    student = _get_student_or_404(uni_id, db)

    if not student.user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Student account is inactive",
        )

    return _identity_response(student)
