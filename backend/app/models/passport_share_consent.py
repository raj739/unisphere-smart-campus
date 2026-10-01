from datetime import datetime

from sqlalchemy import Boolean, DateTime, ForeignKey, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


class PassportShareConsent(Base):
    __tablename__ = "passport_share_consents"

    id: Mapped[int] = mapped_column(
        Integer,
        primary_key=True,
        index=True,
    )

    student_id: Mapped[int] = mapped_column(
        ForeignKey("students.id"),
        nullable=False,
        index=True,
    )

    passport_id: Mapped[int] = mapped_column(
        ForeignKey("academic_passports.id"),
        nullable=False,
        index=True,
    )

    share_token: Mapped[str] = mapped_column(
        String(255),
        nullable=False,
        unique=True,
        index=True,
    )

    recipient_name: Mapped[str] = mapped_column(
        String(200),
        nullable=False,
    )

    recipient_email: Mapped[str | None] = mapped_column(
        String(255),
        nullable=True,
    )

    purpose: Mapped[str] = mapped_column(
        String(500),
        nullable=False,
    )

    scope: Mapped[str] = mapped_column(
        Text,
        nullable=False,
        default="identity,academic",
    )

    status: Mapped[str] = mapped_column(
        String(50),
        nullable=False,
        default="Active",
    )

    expires_at: Mapped[datetime | None] = mapped_column(
        DateTime,
        nullable=True,
    )

    created_at: Mapped[datetime] = mapped_column(
        DateTime,
        nullable=False,
        default=datetime.utcnow,
    )

    revoked_at: Mapped[datetime | None] = mapped_column(
        DateTime,
        nullable=True,
    )

    is_active: Mapped[bool] = mapped_column(
        Boolean,
        nullable=False,
        default=True,
    )
