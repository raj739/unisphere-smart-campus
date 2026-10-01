from datetime import datetime

from sqlalchemy import Boolean, DateTime, Integer, String, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


class RolePermission(Base):
    __tablename__ = "role_permissions"

    __table_args__ = (
        UniqueConstraint(
            "role",
            "permission_id",
            name="uq_role_permission",
        ),
    )

    id: Mapped[int] = mapped_column(
        Integer,
        primary_key=True,
        index=True,
    )

    role: Mapped[str] = mapped_column(
        String(100),
        nullable=False,
        index=True,
    )

    permission_id: Mapped[int] = mapped_column(
        Integer,
        nullable=False,
        index=True,
    )

    is_active: Mapped[bool] = mapped_column(
        Boolean,
        nullable=False,
        default=True,
    )

    created_at: Mapped[datetime] = mapped_column(
        DateTime,
        nullable=False,
        default=datetime.utcnow,
    )
