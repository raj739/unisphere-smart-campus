from datetime import datetime

from sqlalchemy import Boolean, DateTime, Integer, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


class UserPermission(Base):
    __tablename__ = "user_permissions"

    __table_args__ = (
        UniqueConstraint(
            "user_id",
            "permission_id",
            name="uq_user_permission",
        ),
    )

    id: Mapped[int] = mapped_column(
        Integer,
        primary_key=True,
        index=True,
    )

    user_id: Mapped[int] = mapped_column(
        Integer,
        nullable=False,
        index=True,
    )

    permission_id: Mapped[int] = mapped_column(
        Integer,
        nullable=False,
        index=True,
    )

    granted: Mapped[bool] = mapped_column(
        Boolean,
        nullable=False,
        default=True,
    )

    created_at: Mapped[datetime] = mapped_column(
        DateTime,
        nullable=False,
        default=datetime.utcnow,
    )
