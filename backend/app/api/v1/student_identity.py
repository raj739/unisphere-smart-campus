from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.student import Student
from app.models.user import User
from app.schemas.identity import StudentIdentityResponse


router = APIRouter(
    prefix="/identity",
    tags=["Identity Management"],
)


@router.get(
    "/me",
    response_model=StudentIdentityResponse,
)
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

    return StudentIdentityResponse(
        student_id=student.id,
        user_id=student.user_id,
        uni_id=student.uni_id,
        full_name=student.full_name,
        email=current_user.email,
        university_id=student.university_id,
        enrollment_number=student.enrollment_number,
        programme=student.programme,
        current_semester=student.current_semester,
        academic_session=student.academic_session,
        department_id=student.department_id,
        role=current_user.role,
        is_active=current_user.is_active,
    )
