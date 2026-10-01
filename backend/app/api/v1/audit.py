from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import func
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import get_current_user
from app.models.audit_log import AuditLog
from app.schemas.audit import AuditLogListResponse

router = APIRouter(prefix="/audit", tags=["Audit"])


def _is_admin(user) -> bool:
    role = str(getattr(user, "role", "") or "").lower()

    return role in {
        "admin",
        "administrator",
        "super_admin",
        "superadmin",
    }


@router.get("/me", response_model=AuditLogListResponse)
def get_my_audit_logs(
    limit: int = Query(default=50, ge=1, le=200),
    offset: int = Query(default=0, ge=0),
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    query = (
        db.query(AuditLog)
        .filter(AuditLog.user_id == current_user.id)
        .order_by(AuditLog.created_at.desc())
    )

    total = query.with_entities(func.count(AuditLog.id)).scalar() or 0
    items = query.offset(offset).limit(limit).all()

    return AuditLogListResponse(
        items=items,
        total=total,
        limit=limit,
        offset=offset,
    )


@router.get("", response_model=AuditLogListResponse)
def get_audit_logs(
    limit: int = Query(default=50, ge=1, le=200),
    offset: int = Query(default=0, ge=0),
    module: str | None = None,
    action: str | None = None,
    success: bool | None = None,
    user_id: int | None = None,
    entity_type: str | None = None,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    if not _is_admin(current_user):
        raise HTTPException(
            status_code=403,
            detail="Administrator access required.",
        )

    query = db.query(AuditLog)

    if module:
        query = query.filter(AuditLog.module == module)

    if action:
        query = query.filter(AuditLog.action == action)

    if success is not None:
        query = query.filter(AuditLog.success == success)

    if user_id is not None:
        query = query.filter(AuditLog.user_id == user_id)

    if entity_type:
        query = query.filter(AuditLog.entity_type == entity_type)

    query = query.order_by(AuditLog.created_at.desc())

    total = query.with_entities(func.count(AuditLog.id)).scalar() or 0
    items = query.offset(offset).limit(limit).all()

    return AuditLogListResponse(
        items=items,
        total=total,
        limit=limit,
        offset=offset,
    )
