from datetime import datetime

from sqlalchemy import Boolean, DateTime, ForeignKey, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


class EarlyWarning(Base):
    __tablename__ = "early_warnings"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)

    student_id: Mapped[int] = mapped_column(
        ForeignKey("students.id"),
        nullable=False,
        index=True,
    )

    risk_assessment_id: Mapped[int | None] = mapped_column(
        ForeignKey("risk_assessments.id"),
        nullable=True,
        index=True,
    )

    warning_type: Mapped[str] = mapped_column(
        String(50),
        nullable=False,
        index=True,
    )

    severity: Mapped[str] = mapped_column(
        String(30),
        nullable=False,
        default="Medium",
        index=True,
    )

    title: Mapped[str] = mapped_column(
        String(200),
        nullable=False,
    )

    message: Mapped[str] = mapped_column(
        Text,
        nullable=False,
    )

    trigger_value: Mapped[str | None] = mapped_column(
        String(100),
        nullable=True,
    )

    threshold_value: Mapped[str | None] = mapped_column(
        String(100),
        nullable=True,
    )

    recommended_action: Mapped[str] = mapped_column(
        Text,
        nullable=False,
    )

    status: Mapped[str] = mapped_column(
        String(30),
        nullable=False,
        default="Open",
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
        index=True,
    )

    resolved_at: Mapped[datetime | None] = mapped_column(
        DateTime,
        nullable=True,
    )
