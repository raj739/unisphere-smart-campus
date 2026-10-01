from __future__ import annotations

from sqlalchemy import func
from sqlalchemy.orm import Session

from app.models.user import User


class AnalyticsService:

    @staticmethod
    def university_overview(db: Session) -> dict:
        total_users = db.query(func.count(User.id)).scalar() or 0

        students = (
            db.query(func.count(User.id))
            .filter(User.role == "student")
            .scalar()
            or 0
        )

        parents = (
            db.query(func.count(User.id))
            .filter(User.role == "parent")
            .scalar()
            or 0
        )

        admins = (
            db.query(func.count(User.id))
            .filter(
                User.role.in_(
                    [
                        "admin",
                        "administrator",
                        "super_admin",
                        "superadmin",
                    ]
                )
            )
            .scalar()
            or 0
        )

        active_users = (
            db.query(func.count(User.id))
            .filter(User.is_active.is_(True))
            .scalar()
            or 0
        )

        return {
            "total_users": total_users,
            "students": students,
            "parents": parents,
            "administrators": admins,
            "active_users": active_users,
        }

    @staticmethod
    def user_distribution(db: Session) -> list[dict]:
        rows = (
            db.query(
                User.role,
                func.count(User.id),
            )
            .group_by(User.role)
            .order_by(func.count(User.id).desc())
            .all()
        )

        return [
            {
                "role": role or "unknown",
                "count": count,
            }
            for role, count in rows
        ]

    @staticmethod
    def system_health(db: Session) -> dict:
        overview = AnalyticsService.university_overview(db)

        total = overview["total_users"]
        active = overview["active_users"]

        active_percentage = (
            round((active / total) * 100, 2)
            if total > 0
            else 0.0
        )

        return {
            "database": "connected",
            "total_users": total,
            "active_users": active,
            "active_user_percentage": active_percentage,
        }
