from fastapi import Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import get_current_user
from app.models.student import Student
from app.models.user import User
from app.services.rbac_service import RBACService


def require_role(required_role: str):
    def role_checker(
        current_user: User = Depends(get_current_user),
    ) -> User:
        if current_user.role != required_role:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Insufficient permissions",
            )

        return current_user

    return role_checker


def require_roles(*allowed_roles: str):
    def role_checker(
        current_user: User = Depends(get_current_user),
    ) -> User:
        if current_user.role not in allowed_roles:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Insufficient permissions",
            )

        return current_user

    return role_checker


def require_permission(permission_code: str):
    def permission_checker(
        current_user: User = Depends(get_current_user),
        db: Session = Depends(get_db),
    ) -> User:
        if current_user.role in {"admin", "superadmin", "super_admin"}:
            return current_user

        has_perm = RBACService.has_permission(
            db=db,
            user_id=current_user.id,
            role=current_user.role,
            permission=permission_code,
        )
        if not has_perm:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Permission '{permission_code}' required",
            )

        return current_user

    return permission_checker


def verify_student_access(
    current_user: User,
    student: Student,
    db: Session,
) -> None:
    if current_user.role in {"admin", "superadmin", "super_admin", "staff", "faculty"}:
        return

    if current_user.role == "student":
        if student.user_id != current_user.id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Access denied: You can only access your own student profile or data",
            )
        return

    if current_user.role == "parent":
        from app.models.parent_student import ParentStudentLink
        from app.models.parent_student_link_v2 import ParentStudentLinkV2

        link_v2 = (
            db.query(ParentStudentLinkV2)
            .filter(
                ParentStudentLinkV2.parent_user_id == current_user.id,
                ParentStudentLinkV2.student_id == student.id,
                ParentStudentLinkV2.is_active.is_(True),
            )
            .first()
        )
        if link_v2:
            return

        link_v1 = (
            db.query(ParentStudentLink)
            .filter(
                ParentStudentLink.parent_user_id == current_user.id,
                ParentStudentLink.student_id == student.id,
            )
            .first()
        )
        if link_v1:
            return

        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access denied: You can only access data for linked students",
        )

    raise HTTPException(
        status_code=status.HTTP_403_FORBIDDEN,
        detail="Insufficient permissions",
    )


__all__ = [
    "get_current_user",
    "require_role",
    "require_roles",
    "require_permission",
    "verify_student_access",
]

