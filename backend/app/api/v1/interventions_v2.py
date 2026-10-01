from datetime import date, datetime, time

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import require_roles, verify_student_access
from app.core.security import get_current_user
from app.models.early_warning import EarlyWarning
from app.models.intervention import Intervention
from app.models.student import Student
from app.models.user import User
from app.schemas.intervention_v2 import (
    InterventionCreateV2,
    InterventionResponseV2,
    InterventionStatusUpdateV2,
)


router = APIRouter(
    prefix="/interventions-v2",
    tags=["Interventions"],
)


def _get_student_by_uni_id(
    db: Session,
    uni_id: str,
) -> Student:
    student = (
        db.query(Student)
        .filter(Student.uni_id == uni_id)
        .first()
    )

    if not student:
        raise HTTPException(
            status_code=404,
            detail="Student not found.",
        )

    return student


def _response(
    intervention: Intervention,
    student: Student,
    warning: EarlyWarning | None = None,
) -> dict:
    """Map the legacy intervention table to the V2 response contract."""

    # Legacy table stores dates as strings.
    created_at = datetime.combine(date.today(), time.min)
    if intervention.created_date:
        try:
            created_at = datetime.fromisoformat(str(intervention.created_date))
        except (TypeError, ValueError):
            pass

    due_date = None
    if intervention.due_date:
        try:
            due_date = date.fromisoformat(str(intervention.due_date))
        except (TypeError, ValueError):
            pass

    return {
        "id": intervention.id,
        "warning_id": intervention.warning_id,
        "uni_id": student.uni_id,
        "student_name": student.full_name,
        "programme": student.programme,
        "warning_title": warning.title if warning else None,
        "intervention_type": intervention.intervention_type,
        "assigned_to": intervention.assigned_to,
        "priority": intervention.priority,
        "reason": intervention.reason,
        "notes": intervention.notes,
        "outcome": intervention.outcome,
        "due_date": due_date,
        "status": intervention.status,
        "created_at": created_at,
        "updated_at": intervention.updated_at or created_at,
    }


def _warning_for(intervention: Intervention, db: Session) -> EarlyWarning | None:
    if intervention.warning_id is None:
        return None
    return (
        db.query(EarlyWarning)
        .filter(EarlyWarning.id == intervention.warning_id)
        .first()
    )

@router.get(
    "",
    response_model=list[InterventionResponseV2],
    dependencies=[Depends(require_roles("admin", "superadmin", "super_admin", "staff", "faculty"))],
)
def list_interventions(
    status: str | None = None,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    """List all interventions. Staff/admin only."""
    query = db.query(Intervention, Student).join(
        Student, Intervention.student_id == Student.id
    )

    if status:
        query = query.filter(Intervention.status == status)

    return [
        _response(intervention, student, _warning_for(intervention, db))
        for intervention, student in query.order_by(Intervention.id.desc()).all()
    ]


@router.get(
    "/me",
    response_model=list[InterventionResponseV2],
)
def my_interventions(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Return interventions for the currently logged-in student."""
    student = (
        db.query(Student)
        .filter(Student.user_id == current_user.id)
        .first()
    )

    if not student:
        raise HTTPException(status_code=404, detail="Student profile not found.")

    interventions = (
        db.query(Intervention)
        .filter(Intervention.student_id == student.id)
        .order_by(Intervention.id.desc())
        .all()
    )
    return [
        _response(intervention, student, _warning_for(intervention, db))
        for intervention in interventions
    ]


@router.get(
    "/student/{uni_id}",
    response_model=list[InterventionResponseV2],
)
def student_interventions(
    uni_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Get interventions for a specific student. Students can only view their own."""
    student = _get_student_by_uni_id(db, uni_id)

    # Enforce object-level access: student can only see own; staff/admin see all.
    verify_student_access(current_user, student, db)

    interventions = (
        db.query(Intervention)
        .filter(Intervention.student_id == student.id)
        .order_by(Intervention.id.desc())
        .all()
    )
    return [
        _response(intervention, student, _warning_for(intervention, db))
        for intervention in interventions
    ]


@router.post(
    "",
    response_model=InterventionResponseV2,
    dependencies=[Depends(require_roles("admin", "superadmin", "super_admin", "staff", "faculty"))],
)
def create_intervention(
    payload: InterventionCreateV2,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    """Create intervention for a student. Staff/admin only."""
    student = _get_student_by_uni_id(db, payload.uni_id)
    warning = None
    if payload.warning_id is not None:
        warning = (
            db.query(EarlyWarning)
            .filter(EarlyWarning.id == payload.warning_id)
            .first()
        )
        if warning is None:
            raise HTTPException(status_code=404, detail="Early warning not found.")
        if warning.student_id != student.id:
            raise HTTPException(
                status_code=400,
                detail="Early warning does not belong to this student.",
            )
        existing = (
            db.query(Intervention)
            .filter(
                Intervention.warning_id == warning.id,
                Intervention.status.notin_({"Completed", "Cancelled"}),
            )
            .first()
        )
        if existing:
            raise HTTPException(
                status_code=409,
                detail="This warning already has an active intervention.",
            )

    intervention = Intervention(
        student_id=student.id,
        warning_id=payload.warning_id,
        intervention_type=payload.intervention_type,
        assigned_to=payload.assigned_to,
        priority=payload.priority,
        reason=payload.reason,
        due_date=payload.due_date.isoformat() if payload.due_date else None,
        status="Open",
        created_date=datetime.utcnow().date().isoformat(),
    )

    db.add(intervention)
    if warning is not None:
        warning.status = "In Intervention"
        warning.is_active = True
    db.commit()
    db.refresh(intervention)

    return _response(intervention, student, warning)


@router.post(
    "/reconcile-warnings",
    dependencies=[Depends(require_roles("admin", "superadmin", "super_admin"))],
)
def reconcile_intervention_warnings(db: Session = Depends(get_db)):
    type_keywords = {
        "attendance": "Attendance",
        "academic": "Academic",
        "financial": "Fees",
        "fee": "Fees",
        "engagement": "Engagement",
        "success": "OverallRisk",
    }
    interventions = (
        db.query(Intervention)
        .filter(
            Intervention.warning_id.is_(None),
            Intervention.status.notin_({"Completed", "Cancelled"}),
        )
        .order_by(Intervention.id.asc())
        .all()
    )
    linked = 0
    for intervention in interventions:
        intervention_type = intervention.intervention_type.lower()
        warning_type = next(
            (
                value
                for keyword, value in type_keywords.items()
                if keyword in intervention_type
            ),
            None,
        )
        query = db.query(EarlyWarning).filter(
            EarlyWarning.student_id == intervention.student_id,
            EarlyWarning.is_active.is_(True),
            EarlyWarning.status == "Open",
        )
        if warning_type is not None:
            query = query.filter(EarlyWarning.warning_type == warning_type)
        warning = query.order_by(EarlyWarning.id.desc()).first()
        if warning is None:
            continue
        already_linked = (
            db.query(Intervention)
            .filter(
                Intervention.warning_id == warning.id,
                Intervention.id != intervention.id,
                Intervention.status.notin_({"Completed", "Cancelled"}),
            )
            .first()
        )
        if already_linked is not None:
            continue
        intervention.warning_id = warning.id
        intervention.updated_at = datetime.utcnow()
        warning.status = "In Intervention"
        linked += 1
    db.commit()
    return {"linked": linked}


@router.patch(
    "/{intervention_id}/status",
    response_model=InterventionResponseV2,
    dependencies=[Depends(require_roles("admin", "superadmin", "super_admin", "staff", "faculty"))],
)
def update_intervention_status(
    intervention_id: int,
    payload: InterventionStatusUpdateV2,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    """Update intervention status. Staff/admin only."""
    intervention = (
        db.query(Intervention)
        .filter(Intervention.id == intervention_id)
        .first()
    )

    if not intervention:
        raise HTTPException(
            status_code=404,
            detail="Intervention not found.",
        )

    allowed = {
        "Open",
        "Assigned",
        "In Progress",
        "Completed",
        "Cancelled",
    }

    if payload.status not in allowed:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid status. Allowed values: {sorted(allowed)}",
        )

    if payload.status == "Completed" and not (payload.outcome or intervention.outcome):
        raise HTTPException(
            status_code=400,
            detail="An outcome is required before completing an intervention.",
        )

    intervention.status = payload.status
    if payload.assigned_to is not None:
        intervention.assigned_to = payload.assigned_to.strip() or None
    if payload.due_date is not None:
        intervention.due_date = payload.due_date.isoformat()
    if payload.notes is not None:
        intervention.notes = payload.notes.strip() or None
    if payload.outcome is not None:
        intervention.outcome = payload.outcome.strip() or None
    intervention.updated_at = datetime.utcnow()

    warning = _warning_for(intervention, db)
    if warning is not None:
        if payload.status == "Completed":
            warning.status = "Resolved"
            warning.is_active = False
            warning.resolved_at = datetime.utcnow()
        elif payload.status == "Cancelled":
            warning.status = "Open"
            warning.is_active = True
            warning.resolved_at = None
        else:
            warning.status = "In Intervention"
            warning.is_active = True

    db.commit()
    db.refresh(intervention)

    student = db.query(Student).filter(Student.id == intervention.student_id).first()
    if student is None:
        raise HTTPException(status_code=404, detail="Student not found.")

    return _response(intervention, student, warning)

