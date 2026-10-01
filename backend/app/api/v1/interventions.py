from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import require_role
from app.models.intervention import AcademicIntervention
from app.models.student import Student
from app.models.user import User
from app.schemas.intervention import (
    InterventionCreateRequest,
    InterventionResponse,
    InterventionStatusUpdate,
)


router = APIRouter(
    prefix="/interventions",
    tags=["Academic Interventions"],
)


def build_response(
    intervention: AcademicIntervention,
    student: Student,
):
    return InterventionResponse(
        id=intervention.id,
        uni_id=student.uni_id,
        student_name=student.full_name,
        intervention_type=intervention.intervention_type,
        assigned_to=intervention.assigned_to,
        priority=intervention.priority,
        reason=intervention.reason,
        due_date=intervention.due_date,
        status=intervention.status,
        created_date=intervention.created_date,
    )


@router.get(
    "",
    response_model=list[InterventionResponse],
)
def get_interventions(
    current_user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    records = (
        db.query(
            AcademicIntervention,
            Student,
        )
        .join(
            Student,
            AcademicIntervention.student_id == Student.id,
        )
        .order_by(AcademicIntervention.id.desc())
        .all()
    )

    return [
        build_response(intervention, student)
        for intervention, student in records
    ]


@router.post(
    "",
    response_model=InterventionResponse,
    status_code=status.HTTP_201_CREATED,
)
def create_intervention(
    request: InterventionCreateRequest,
    current_user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    student = (
        db.query(Student)
        .filter(Student.uni_id == request.uni_id)
        .first()
    )

    if student is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Student not found",
        )

    intervention = AcademicIntervention(
        student_id=student.id,
        intervention_type=request.intervention_type,
        assigned_to=request.assigned_to,
        priority=request.priority,
        reason=request.reason,
        due_date=request.due_date,
        status="Pending",
        created_date=datetime.now().strftime("%Y-%m-%d"),
    )

    db.add(intervention)
    db.commit()
    db.refresh(intervention)

    return build_response(
        intervention,
        student,
    )


@router.get(
    "/{intervention_id}",
    response_model=InterventionResponse,
)
def get_intervention(
    intervention_id: int,
    current_user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    record = (
        db.query(
            AcademicIntervention,
            Student,
        )
        .join(
            Student,
            AcademicIntervention.student_id == Student.id,
        )
        .filter(
            AcademicIntervention.id == intervention_id
        )
        .first()
    )

    if record is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Intervention not found",
        )

    intervention, student = record

    return build_response(
        intervention,
        student,
    )


@router.patch(
    "/{intervention_id}/status",
    response_model=InterventionResponse,
)
def update_intervention_status(
    intervention_id: int,
    request: InterventionStatusUpdate,
    current_user: User = Depends(require_role("admin")),
    db: Session = Depends(get_db),
):
    record = (
        db.query(
            AcademicIntervention,
            Student,
        )
        .join(
            Student,
            AcademicIntervention.student_id == Student.id,
        )
        .filter(
            AcademicIntervention.id == intervention_id
        )
        .first()
    )

    if record is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Intervention not found",
        )

    intervention, student = record

    intervention.status = request.status

    db.commit()
    db.refresh(intervention)

    return build_response(
        intervention,
        student,
    )
