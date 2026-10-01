from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_user, verify_student_access
from app.models.student import Student
from app.models.user import User


router = APIRouter(
    prefix="/students",
    tags=["Students"],
)


@router.get("/me")
def get_my_student_profile(
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

    return {
        "id": student.id,
        "uni_id": student.uni_id,
        "university_id": student.university_id,
        "enrollment_number": student.enrollment_number,
        "full_name": student.full_name,
        "programme": student.programme,
        "current_semester": student.current_semester,
        "academic_session": student.academic_session,
        "department_id": student.department_id,
        "user_id": student.user_id,
    }


@router.get("/{uni_id}")
def get_student_by_uni_id(
    uni_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
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

    verify_student_access(current_user, student, db)

    return {
        "id": student.id,
        "uni_id": student.uni_id,
        "university_id": student.university_id,
        "enrollment_number": student.enrollment_number,
        "full_name": student.full_name,
        "programme": student.programme,
        "current_semester": student.current_semester,
        "academic_session": student.academic_session,
        "department_id": student.department_id,
        "user_id": student.user_id,
    }
