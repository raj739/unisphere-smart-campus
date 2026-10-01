from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import desc
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import require_roles
from app.core.security import get_current_user
from app.models.early_warning import EarlyWarning
from app.models.intervention import Intervention
from app.models.risk_assessment import RiskAssessment
from app.models.student import Student
from app.schemas.early_warning import (
    EarlyWarningGenerateRequest,
    EarlyWarningResponse,
)
from app.services.early_warning_engine import EarlyWarningEngine
from app.services.risk_engine import RiskEngine


router = APIRouter(
    prefix="/early-warning",
    tags=["Early Warning"],
)


def _admin_response(warning: EarlyWarning, db: Session) -> dict:
    student = db.query(Student).filter(Student.id == warning.student_id).first()
    intervention = (
        db.query(Intervention)
        .filter(
            Intervention.warning_id == warning.id,
            Intervention.status.notin_({"Completed", "Cancelled"}),
        )
        .order_by(Intervention.id.desc())
        .first()
    )
    return {
        "id": warning.id,
        "student_id": warning.student_id,
        "uni_id": student.uni_id if student else None,
        "student_name": student.full_name if student else None,
        "programme": student.programme if student else None,
        "intervention_id": intervention.id if intervention else None,
        "risk_assessment_id": warning.risk_assessment_id,
        "warning_type": warning.warning_type,
        "severity": warning.severity,
        "title": warning.title,
        "message": warning.message,
        "trigger_value": warning.trigger_value,
        "threshold_value": warning.threshold_value,
        "recommended_action": warning.recommended_action,
        "status": warning.status,
        "is_active": warning.is_active,
        "created_at": warning.created_at,
        "resolved_at": warning.resolved_at,
    }


@router.post(
    "/generate",
    response_model=list[EarlyWarningResponse],
)
def generate_warnings(
    payload: EarlyWarningGenerateRequest,
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

    risk_result = RiskEngine.calculate(
        attendance=payload.attendance,
        academic_percentage=payload.academic_percentage,
        fee_due=payload.fee_due,
        engagement=payload.engagement,
    )

    risk_assessment = (
        db.query(RiskAssessment)
        .filter(
            RiskAssessment.student_id == student.id,
            RiskAssessment.is_active.is_(True),
        )
        .order_by(desc(RiskAssessment.calculated_at))
        .first()
    )

    signals = EarlyWarningEngine.generate(
        attendance=payload.attendance,
        academic_percentage=payload.academic_percentage,
        fee_due=payload.fee_due,
        engagement=payload.engagement,
        risk_score=risk_result.score,
        risk_level=risk_result.level,
    )

    # Keep the warning list current for this student.
    db.query(EarlyWarning).filter(
        EarlyWarning.student_id == student.id,
        EarlyWarning.is_active.is_(True),
        EarlyWarning.status == "Open",
    ).update(
        {
            "is_active": False,
            "status": "Superseded",
        },
        synchronize_session=False,
    )

    created = []

    for signal in signals:
        warning = EarlyWarning(
            student_id=student.id,
            risk_assessment_id=(
                risk_assessment.id if risk_assessment else None
            ),
            warning_type=signal.warning_type,
            severity=signal.severity,
            title=signal.title,
            message=signal.message,
            trigger_value=signal.trigger_value,
            threshold_value=signal.threshold_value,
            recommended_action=signal.recommended_action,
            status="Open",
            is_active=True,
        )

        db.add(warning)
        created.append(warning)

    db.commit()

    for warning in created:
        db.refresh(warning)

    return created


@router.get(
    "/me",
    response_model=list[EarlyWarningResponse],
)
def get_my_warnings(
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

    return (
        db.query(EarlyWarning)
        .filter(
            EarlyWarning.student_id == student.id,
            EarlyWarning.is_active.is_(True),
            EarlyWarning.status.in_({"Open", "In Intervention"}),
        )
        .order_by(desc(EarlyWarning.created_at))
        .all()
    )


@router.get(
    "/students",
    response_model=list[EarlyWarningResponse],
    dependencies=[Depends(require_roles("admin", "superadmin", "super_admin", "staff", "faculty"))],
)
def get_all_warnings(
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    """List all active early warnings. Staff/admin only."""
    warnings = (
        db.query(EarlyWarning)
        .filter(
            EarlyWarning.is_active.is_(True),
            EarlyWarning.status.in_({"Open", "In Intervention"}),
        )
        .order_by(desc(EarlyWarning.created_at))
        .all()
    )
    return [_admin_response(warning, db) for warning in warnings]


@router.patch(
    "/{warning_id}/resolve",
    response_model=EarlyWarningResponse,
)
def resolve_warning(
    warning_id: int,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    warning = (
        db.query(EarlyWarning)
        .filter(EarlyWarning.id == warning_id)
        .first()
    )

    if not warning:
        raise HTTPException(
            status_code=404,
            detail="Early warning not found.",
        )

    active_intervention = (
        db.query(Intervention)
        .filter(
            Intervention.warning_id == warning.id,
            Intervention.status.notin_({"Completed", "Cancelled"}),
        )
        .first()
    )
    if active_intervention is not None:
        raise HTTPException(
            status_code=409,
            detail="Complete or cancel the linked intervention before resolving this warning.",
        )

    # Staff/admin can resolve any warning; students can only resolve their own.
    _staff = {"admin", "superadmin", "super_admin", "staff", "faculty"}
    if current_user.role not in _staff:
        from app.models.student import Student as _Student
        student = (
            db.query(_Student)
            .filter(_Student.user_id == current_user.id)
            .first()
        )
        if student is None or warning.student_id != student.id:
            raise HTTPException(
                status_code=403,
                detail="You are not authorized to resolve this warning.",
            )

    warning.status = "Resolved"
    warning.is_active = False
    warning.resolved_at = datetime.utcnow()

    db.commit()
    db.refresh(warning)

    return warning
