from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import get_current_user
from app.models.academic_passport import AcademicPassport
from app.models.passport_share_consent import PassportShareConsent
from app.models.student import Student
from app.schemas.passport_share import (
    PassportShareConsentCreate,
    PassportShareConsentResponse,
    PassportShareVerifyResponse,
)
from app.services.passport_sharing_service import (
    PassportSharingService,
)


router = APIRouter(
    prefix="/passport-sharing",
    tags=["Passport Secure Sharing"],
)


def get_current_student(
    db: Session,
    current_user,
) -> Student:

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

    return student


def get_or_create_passport(
    db: Session,
    student: Student,
) -> AcademicPassport:

    passport = (
        db.query(AcademicPassport)
        .filter(
            AcademicPassport.student_id == student.id,
        )
        .first()
    )

    if not passport:
        raise HTTPException(
            status_code=404,
            detail="Academic Passport not found.",
        )

    return passport


@router.post(
    "",
    response_model=PassportShareConsentResponse,
)
def create_share_consent(
    payload: PassportShareConsentCreate,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    student = get_current_student(
        db,
        current_user,
    )

    passport = get_or_create_passport(
        db,
        student,
    )

    if payload.expires_at is not None:
        if payload.expires_at <= datetime.utcnow():
            raise HTTPException(
                status_code=400,
                detail="Expiry time must be in the future.",
            )

    consent = PassportShareConsent(
        student_id=student.id,
        passport_id=passport.id,
        share_token=PassportSharingService.generate_token(),
        recipient_name=payload.recipient_name,
        recipient_email=payload.recipient_email,
        purpose=payload.purpose,
        scope=payload.scope,
        expires_at=payload.expires_at,
        status="Active",
        is_active=True,
    )

    db.add(consent)
    db.commit()
    db.refresh(consent)

    return consent


@router.get(
    "/me",
    response_model=list[PassportShareConsentResponse],
)
def get_my_consents(
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    student = get_current_student(
        db,
        current_user,
    )

    consents = (
        db.query(PassportShareConsent)
        .filter(
            PassportShareConsent.student_id == student.id,
        )
        .order_by(
            PassportShareConsent.created_at.desc()
        )
        .all()
    )

    for consent in consents:
        PassportSharingService.expire_if_needed(
            db,
            consent,
        )

    return consents


@router.patch(
    "/{consent_id}/revoke",
    response_model=PassportShareConsentResponse,
)
def revoke_consent(
    consent_id: int,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    student = get_current_student(
        db,
        current_user,
    )

    consent = (
        db.query(PassportShareConsent)
        .filter(
            PassportShareConsent.id == consent_id,
            PassportShareConsent.student_id == student.id,
        )
        .first()
    )

    if not consent:
        raise HTTPException(
            status_code=404,
            detail="Share consent not found.",
        )

    return PassportSharingService.revoke(
        db,
        consent,
    )


@router.get(
    "/verify/{share_token}",
    response_model=PassportShareVerifyResponse,
)
def verify_shared_passport(
    share_token: str,
    db: Session = Depends(get_db),
):
    consent = (
        db.query(PassportShareConsent)
        .filter(
            PassportShareConsent.share_token == share_token,
        )
        .first()
    )

    if not consent:
        return PassportShareVerifyResponse(
            valid=False,
            status="Not Found",
        )

    consent = PassportSharingService.expire_if_needed(
        db,
        consent,
    )

    if not PassportSharingService.is_valid(consent):
        return PassportShareVerifyResponse(
            valid=False,
            status=consent.status,
            recipient_name=consent.recipient_name,
            purpose=consent.purpose,
            expires_at=consent.expires_at,
        )

    passport = (
        db.query(AcademicPassport)
        .filter(
            AcademicPassport.id == consent.passport_id,
        )
        .first()
    )

    if not passport or not passport.is_verified:
        return PassportShareVerifyResponse(
            valid=False,
            status="Invalid Passport",
        )

    data = PassportSharingService.build_shared_passport(
        passport,
        consent,
    )

    return PassportShareVerifyResponse(
        **data,
    )
