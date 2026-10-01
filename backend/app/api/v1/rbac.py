from app.services.rbac_coverage_service import RBACCoverageService
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import get_current_user
from app.models.permission import Permission
from app.models.role_permission import RolePermission
from app.models.user_permission import UserPermission
from app.schemas.rbac import (
    PermissionCheckRequest,
    PermissionCheckResponse,
    PermissionResponse,
    RolePermissionCreate,
    UserPermissionCreate,
)
from app.services.rbac_service import RBACService


router = APIRouter(
    prefix="/rbac",
    tags=["Advanced RBAC"],
)


DEFAULT_PERMISSIONS = [
    ("system.admin", "System Administration", "Full system administration", "system"),
    ("users.read", "View Users", "View user records", "users"),
    ("users.manage", "Manage Users", "Create and manage users", "users"),
    ("students.read", "View Students", "View student records", "students"),
    ("students.manage", "Manage Students", "Manage student records", "students"),
    ("academics.read", "View Academics", "View academic records", "academics"),
    ("academics.manage", "Manage Academics", "Manage academic records", "academics"),
    ("attendance.read", "View Attendance", "View attendance records", "attendance"),
    ("attendance.manage", "Manage Attendance", "Manage attendance records", "attendance"),
    ("examinations.read", "View Examinations", "View examination records", "examinations"),
    ("examinations.manage", "Manage Examinations", "Manage examination records", "examinations"),
    ("fees.read", "View Fees", "View fee information", "fees"),
    ("fees.manage", "Manage Fees", "Manage fee information", "fees"),
    ("hostel.read", "View Hostel", "View hostel information", "hostel"),
    ("hostel.manage", "Manage Hostel", "Manage hostel information", "hostel"),
    ("transport.read", "View Transport", "View transport information", "transport"),
    ("transport.manage", "Manage Transport", "Manage transport information", "transport"),
    ("helpdesk.read", "View Helpdesk", "View helpdesk information", "helpdesk"),
    ("helpdesk.manage", "Manage Helpdesk", "Manage helpdesk information", "helpdesk"),
    ("notifications.read", "View Notifications", "View notifications", "notifications"),
    ("notifications.manage", "Manage Notifications", "Manage notifications", "notifications"),
    ("ai.use", "Use AI", "Use UniSphere AI services", "ai"),
    ("risk.read", "View Risk", "View risk assessments", "risk"),
    ("risk.manage", "Manage Risk", "Manage risk assessments", "risk"),
    ("interventions.read", "View Interventions", "View interventions", "interventions"),
    ("interventions.manage", "Manage Interventions", "Manage interventions", "interventions"),
    ("passport.read", "View Academic Passport", "View academic passport", "passport"),
    ("passport.share", "Share Academic Passport", "Create secure passport shares", "passport"),
    ("passport.verify", "Verify Academic Passport", "Verify passport shares", "passport"),
    ("reports.read", "View Reports", "View institutional reports", "reports"),
    ("audit.read", "View Audit Logs", "View audit records", "audit"),
]


def admin_guard(current_user):
    role = str(getattr(current_user, "role", "")).lower()

    if role not in {
        "admin",
        "administrator",
        "super_admin",
        "superadmin",
    }:
        raise HTTPException(
            status_code=403,
            detail="Administrator access required.",
        )

    return current_user


@router.post(
    "/initialize",
    response_model=dict,
)
def initialize_rbac(
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    admin_guard(current_user)

    created = 0

    for code, name, description, module in DEFAULT_PERMISSIONS:

        permission = (
            db.query(Permission)
            .filter(Permission.code == code)
            .first()
        )

        if not permission:
            permission = Permission(
                code=code,
                name=name,
                description=description,
                module=module,
                is_active=True,
            )

            db.add(permission)
            db.flush()
            created += 1

    db.commit()

    admin_role = str(current_user.role)

    all_permissions = db.query(Permission).all()

    for permission in all_permissions:

        existing = (
            db.query(RolePermission)
            .filter(
                RolePermission.role == admin_role,
                RolePermission.permission_id == permission.id,
            )
            .first()
        )

        if not existing:
            db.add(
                RolePermission(
                    role=admin_role,
                    permission_id=permission.id,
                    is_active=True,
                )
            )

    db.commit()

    return {
        "status": "initialized",
        "permissions_created": created,
        "admin_role": admin_role,
    }


@router.get(
    "/permissions",
    response_model=list[PermissionResponse],
)
def list_permissions(
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    admin_guard(current_user)

    return (
        db.query(Permission)
        .order_by(
            Permission.module.asc(),
            Permission.code.asc(),
        )
        .all()
    )


@router.post(
    "/role-permission",
    response_model=dict,
)
def assign_role_permission(
    payload: RolePermissionCreate,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    admin_guard(current_user)

    permission = (
        db.query(Permission)
        .filter(
            Permission.code == payload.permission_code,
            Permission.is_active.is_(True),
        )
        .first()
    )

    if not permission:
        raise HTTPException(
            status_code=404,
            detail="Permission not found.",
        )

    existing = (
        db.query(RolePermission)
        .filter(
            RolePermission.role == payload.role,
            RolePermission.permission_id == permission.id,
        )
        .first()
    )

    if existing:
        existing.is_active = True
    else:
        db.add(
            RolePermission(
                role=payload.role,
                permission_id=permission.id,
                is_active=True,
            )
        )

    db.commit()

    return {
        "status": "assigned",
        "role": payload.role,
        "permission": payload.permission_code,
    }


@router.post(
    "/user-permission",
    response_model=dict,
)
def assign_user_permission(
    payload: UserPermissionCreate,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    admin_guard(current_user)

    permission = (
        db.query(Permission)
        .filter(
            Permission.code == payload.permission_code,
            Permission.is_active.is_(True),
        )
        .first()
    )

    if not permission:
        raise HTTPException(
            status_code=404,
            detail="Permission not found.",
        )

    existing = (
        db.query(UserPermission)
        .filter(
            UserPermission.user_id == payload.user_id,
            UserPermission.permission_id == permission.id,
        )
        .first()
    )

    if existing:
        existing.granted = payload.granted
    else:
        db.add(
            UserPermission(
                user_id=payload.user_id,
                permission_id=permission.id,
                granted=payload.granted,
            )
        )

    db.commit()

    return {
        "status": "updated",
        "user_id": payload.user_id,
        "permission": payload.permission_code,
        "granted": payload.granted,
    }


@router.post(
    "/check",
    response_model=PermissionCheckResponse,
)
def check_permission(
    payload: PermissionCheckRequest,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    allowed = RBACService.has_permission(
        db=db,
        user_id=current_user.id,
        role=current_user.role,
        permission=payload.permission_code,
    )

    return PermissionCheckResponse(
        permission_code=payload.permission_code,
        allowed=allowed,
    )


@router.get(
    "/me",
    response_model=list[str],
)
def my_permissions(
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    return sorted(
        RBACService.get_user_permissions(
            db=db,
            user_id=current_user.id,
            role=current_user.role,
        )
    )


@router.get("/coverage")
def rbac_coverage(current_user=Depends(get_current_user)):
    """Return RBAC coverage information for administrators."""

    role = getattr(current_user, "role", None)

    if role not in {
        "admin",
        "administrator",
        "super_admin",
        "superadmin",
    }:
        raise HTTPException(
            status_code=403,
            detail="Administrator access required",
        )

    return RBACCoverageService.scan_api_directory()