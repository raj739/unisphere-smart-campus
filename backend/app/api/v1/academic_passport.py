from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import get_current_user
from app.models.academic_passport import AcademicPassport
from app.models.student import Student
from app.schemas.academic_passport import (
    AcademicPassportResponse,
    AcademicPassportVerifyResponse,
)
from app.services.academic_passport_service import (
    AcademicPassportService,
)


router = APIRouter(
    prefix="/academic-passport",
    tags=["Academic Passport"],
)


@router.post(
    "/generate",
    response_model=AcademicPassportResponse,
)
def generate_passport(
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    student = (
        db.query(Student)
        .filter(Student.user_id == current_user.id)
        .first()
    )

    if not student:
        raise HTTPException(
            status_code=404,
            detail="Student profile not found.",
        )

    return AcademicPassportService.generate_or_update(
        db=db,
        student=student,
    )


@router.get(
    "/me",
    response_model=AcademicPassportResponse,
)
def get_my_passport(
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    student = (
        db.query(Student)
        .filter(Student.user_id == current_user.id)
        .first()
    )

    if not student:
        raise HTTPException(
            status_code=404,
            detail="Student profile not found.",
        )

    passport = (
        db.query(AcademicPassport)
        .filter(
            AcademicPassport.student_id == student.id,
        )
        .first()
    )

    if not passport:
        passport = AcademicPassportService.generate_or_update(
            db=db,
            student=student,
        )

    return passport


@router.get(
    "/verify/{verification_token}",
    response_model=AcademicPassportVerifyResponse,
)
def verify_passport(
    verification_token: str,
    db: Session = Depends(get_db),
):
    passport = (
        db.query(AcademicPassport)
        .filter(
            AcademicPassport.verification_token
            == verification_token,
            AcademicPassport.is_verified.is_(True),
        )
        .first()
    )

    if not passport:
        return AcademicPassportVerifyResponse(
            valid=False,
            verified_at=datetime.utcnow(),
        )

    return AcademicPassportVerifyResponse(
        valid=True,
        passport_number=passport.passport_number,
        full_name=passport.full_name,
        uni_id=passport.uni_id,
        programme=passport.programme,
        status=passport.status,
        verified_at=datetime.utcnow(),
    )


@router.post(
    "/regenerate",
    response_model=AcademicPassportResponse,
)
def regenerate_passport(
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    student = (
        db.query(Student)
        .filter(Student.user_id == current_user.id)
        .first()
    )

    if not student:
        raise HTTPException(
            status_code=404,
            detail="Student profile not found.",
        )

    passport = (
        db.query(AcademicPassport)
        .filter(
            AcademicPassport.student_id == student.id,
        )
        .first()
    )

    if passport:
        passport.verification_token = (
            AcademicPassportService._token()
        )
        passport.updated_at = datetime.utcnow()
        passport.is_verified = True
        db.commit()
        db.refresh(passport)
        return passport

    return AcademicPassportService.generate_or_update(
        db=db,
        student=student,
    )
