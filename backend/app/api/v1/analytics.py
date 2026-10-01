from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import get_current_user
from app.schemas.analytics import (
    RoleDistributionItem,
    SystemHealthResponse,
    UniversityOverviewResponse,
)
from app.services.analytics_service import AnalyticsService

router = APIRouter(
    prefix="/analytics",
    tags=["Analytics"],
)


def _is_admin(user) -> bool:
    role = str(
        getattr(user, "role", "") or ""
    ).lower()

    return role in {
        "admin",
        "administrator",
        "super_admin",
        "superadmin",
    }


@router.get(
    "/overview",
    response_model=UniversityOverviewResponse,
)
def get_university_overview(
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    if not _is_admin(current_user):
        raise HTTPException(
            status_code=403,
            detail="Administrator access required.",
        )

    return AnalyticsService.university_overview(db)


@router.get(
    "/role-distribution",
    response_model=list[RoleDistributionItem],
)
def get_role_distribution(
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    if not _is_admin(current_user):
        raise HTTPException(
            status_code=403,
            detail="Administrator access required.",
        )

    return AnalyticsService.user_distribution(db)


@router.get(
    "/health",
    response_model=SystemHealthResponse,
)
def get_system_health(
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    if not _is_admin(current_user):
        raise HTTPException(
            status_code=403,
            detail="Administrator access required.",
        )

    return AnalyticsService.system_health(db)
