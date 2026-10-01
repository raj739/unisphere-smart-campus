from sqlalchemy.orm import Session

from app.models.permission import Permission
from app.models.role_permission import RolePermission
from app.models.user_permission import UserPermission


class RBACService:

    @staticmethod
    def get_user_permissions(
        db: Session,
        user_id: int,
        role: str,
    ) -> set[str]:

        role_rows = (
            db.query(Permission.code)
            .join(
                RolePermission,
                RolePermission.permission_id == Permission.id,
            )
            .filter(
                RolePermission.role == role,
                RolePermission.is_active.is_(True),
                Permission.is_active.is_(True),
            )
            .all()
        )

        permissions = {
            row[0]
            for row in role_rows
        }

        overrides = (
            db.query(
                Permission.code,
                UserPermission.granted,
            )
            .join(
                UserPermission,
                UserPermission.permission_id == Permission.id,
            )
            .filter(
                UserPermission.user_id == user_id,
                Permission.is_active.is_(True),
            )
            .all()
        )

        for code, granted in overrides:
            if granted:
                permissions.add(code)
            else:
                permissions.discard(code)

        return permissions

    @classmethod
    def has_permission(
        cls,
        db: Session,
        user_id: int,
        role: str,
        permission: str,
    ) -> bool:

        permissions = cls.get_user_permissions(
            db=db,
            user_id=user_id,
            role=role,
        )

        if "*" in permissions:
            return True

        return permission in permissions
