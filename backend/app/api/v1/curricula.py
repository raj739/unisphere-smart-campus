from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session, joinedload

from app.core.database import get_db
from app.core.dependencies import require_role
from app.models.curriculum import Curriculum
from app.models.curriculum_course import CurriculumCourse
from app.models.programme import Programme
from app.schemas.curriculum import (
    CurriculumDetailResponse,
    CurriculumStatusUpdateRequest,
    CurriculumSummaryResponse,
)


router = APIRouter(prefix="/curricula", tags=["Curricula"])
CURRICULUM_STATUSES = {"draft", "published", "archived"}


def _summary(curriculum: Curriculum) -> dict:
    courses = curriculum.courses
    return {
        "id": curriculum.id,
        "catalog_key": curriculum.catalog_key,
        "programme_id": curriculum.programme_id,
        "programme_name": curriculum.programme.name,
        "specialization_id": curriculum.specialization_id,
        "specialization_name": (
            curriculum.specialization.name if curriculum.specialization else "Plain"
        ),
        "academic_session": (
            curriculum.academic_session.name if curriculum.academic_session else None
        ),
        "name": curriculum.name,
        "version": curriculum.version,
        "status": curriculum.status,
        "is_demo": curriculum.is_demo,
        "source_name": curriculum.source_name,
        "disclaimer": curriculum.disclaimer,
        "semester_count": len({item.semester_number for item in courses}),
        "course_count": len(courses),
        "total_credits": sum(item.total_credits for item in courses),
        "created_at": curriculum.created_at,
        "updated_at": curriculum.updated_at,
    }


def _query(db: Session):
    return db.query(Curriculum).options(
        joinedload(Curriculum.programme),
        joinedload(Curriculum.specialization),
        joinedload(Curriculum.academic_session),
        joinedload(Curriculum.courses).joinedload(CurriculumCourse.course),
    )


@router.get(
    "",
    response_model=list[CurriculumSummaryResponse],
    dependencies=[Depends(require_role("admin"))],
)
def list_curricula(
    programme_id: int | None = None,
    specialization_id: int | None = None,
    curriculum_status: str | None = None,
    db: Session = Depends(get_db),
):
    query = _query(db)
    if programme_id is not None:
        query = query.filter(Curriculum.programme_id == programme_id)
    if specialization_id is not None:
        query = query.filter(Curriculum.specialization_id == specialization_id)
    if curriculum_status:
        query = query.filter(Curriculum.status == curriculum_status)
    return [
        _summary(curriculum)
        for curriculum in query.order_by(Curriculum.name, Curriculum.version.desc()).all()
    ]


@router.get(
    "/programmes/{programme_id}",
    response_model=list[CurriculumSummaryResponse],
    dependencies=[Depends(require_role("admin"))],
)
def list_programme_curricula(
    programme_id: int,
    curriculum_status: str | None = None,
    db: Session = Depends(get_db),
):
    if db.query(Programme).filter(Programme.id == programme_id).first() is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Programme not found",
        )

    query = _query(db).filter(Curriculum.programme_id == programme_id)
    if curriculum_status:
        query = query.filter(Curriculum.status == curriculum_status)

    curricula = query.order_by(Curriculum.name, Curriculum.version.desc()).all()
    return [_summary(curriculum) for curriculum in curricula]


@router.get(
    "/{curriculum_id}",
    response_model=CurriculumDetailResponse,
    dependencies=[Depends(require_role("admin"))],
)
def get_curriculum(
    curriculum_id: int,
    db: Session = Depends(get_db),
):
    curriculum = _query(db).filter(Curriculum.id == curriculum_id).first()
    if curriculum is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Curriculum not found",
        )

    response = _summary(curriculum)
    response["courses"] = [
        {
            "id": item.id,
            "course_id": item.course_id,
            "course_code": item.course.code,
            "course_name": item.course.name,
            "semester_number": item.semester_number,
            "source_paper_code": item.source_paper_code,
            "paper_type": item.paper_type,
            "theory_credits": item.theory_credits,
            "practical_credits": item.practical_credits,
            "total_credits": item.total_credits,
            "has_practical": item.has_practical,
            "display_order": item.display_order,
            "weekly_hours": item.weekly_hours,
            "max_marks": item.max_marks,
            "passing_marks": item.passing_marks,
            "elective_group": item.elective_group,
        }
        for item in curriculum.courses
    ]
    return response


@router.patch(
    "/{curriculum_id}/status",
    response_model=CurriculumSummaryResponse,
    dependencies=[Depends(require_role("admin"))],
)
def update_curriculum_status(
    curriculum_id: int,
    request: CurriculumStatusUpdateRequest,
    db: Session = Depends(get_db),
):
    normalized_status = request.status.strip().lower()
    if normalized_status not in CURRICULUM_STATUSES:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Curriculum status must be draft, published, or archived",
        )

    curriculum = _query(db).filter(Curriculum.id == curriculum_id).first()
    if curriculum is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Curriculum not found",
        )

    curriculum.status = normalized_status
    db.commit()
    db.refresh(curriculum)
    return _summary(curriculum)
