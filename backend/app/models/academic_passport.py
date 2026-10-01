from datetime import datetime

from sqlalchemy import Boolean, DateTime, ForeignKey, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


class AcademicPassport(Base):
    __tablename__ = "academic_passports"

    id: Mapped[int] = mapped_column(
        Integer,
        primary_key=True,
        index=True,
    )

    student_id: Mapped[int] = mapped_column(
        ForeignKey("students.id"),
        nullable=False,
        unique=True,
        index=True,
    )

    passport_number: Mapped[str] = mapped_column(
        String(100),
        nullable=False,
        unique=True,
        index=True,
    )

    verification_token: Mapped[str] = mapped_column(
        String(255),
        nullable=False,
        unique=True,
        index=True,
    )

    full_name: Mapped[str] = mapped_column(
        String(200),
        nullable=False,
    )

    uni_id: Mapped[str] = mapped_column(
        String(100),
        nullable=False,
        index=True,
    )

    programme: Mapped[str | None] = mapped_column(
        String(200),
        nullable=True,
    )

    current_semester: Mapped[int | None] = mapped_column(
        Integer,
        nullable=True,
    )

    academic_session: Mapped[str | None] = mapped_column(
        String(100),
        nullable=True,
    )

    status: Mapped[str] = mapped_column(
        String(50),
        nullable=False,
        default="Active",
    )

    summary: Mapped[str] = mapped_column(
        Text,
        nullable=False,
        default="",
    )

    is_verified: Mapped[bool] = mapped_column(
        Boolean,
        nullable=False,
        default=True,
    )

    generated_at: Mapped[datetime] = mapped_column(
        DateTime,
        nullable=False,
        default=datetime.utcnow,
    )

    updated_at: Mapped[datetime] = mapped_column(
        DateTime,
        nullable=False,
        default=datetime.utcnow,
    )
