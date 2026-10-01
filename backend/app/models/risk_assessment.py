from datetime import datetime

from sqlalchemy import Boolean, DateTime, Float, ForeignKey, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


class RiskAssessment(Base):
    __tablename__ = "risk_assessments"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)

    student_id: Mapped[int] = mapped_column(
        ForeignKey("students.id"),
        nullable=False,
        index=True,
    )

    risk_score: Mapped[float] = mapped_column(Float, nullable=False, default=0.0)
    risk_level: Mapped[str] = mapped_column(
        String(30),
        nullable=False,
        default="Low",
        index=True,
    )

    attendance_score: Mapped[float] = mapped_column(
        Float,
        nullable=False,
        default=0.0,
    )

    academic_score: Mapped[float] = mapped_column(
        Float,
        nullable=False,
        default=0.0,
    )

    fee_score: Mapped[float] = mapped_column(
        Float,
        nullable=False,
        default=0.0,
    )

    engagement_score: Mapped[float] = mapped_column(
        Float,
        nullable=False,
        default=0.0,
    )

    attendance_weight: Mapped[float] = mapped_column(
        Float,
        nullable=False,
        default=0.40,
    )

    academic_weight: Mapped[float] = mapped_column(
        Float,
        nullable=False,
        default=0.30,
    )

    fee_weight: Mapped[float] = mapped_column(
        Float,
        nullable=False,
        default=0.15,
    )

    engagement_weight: Mapped[float] = mapped_column(
        Float,
        nullable=False,
        default=0.15,
    )

    explanation: Mapped[str] = mapped_column(
        Text,
        nullable=False,
        default="",
    )

    recommended_action: Mapped[str] = mapped_column(
        Text,
        nullable=False,
        default="Continue regular monitoring.",
    )

    is_active: Mapped[bool] = mapped_column(
        Boolean,
        nullable=False,
        default=True,
    )

    calculated_at: Mapped[datetime] = mapped_column(
        DateTime,
        nullable=False,
        default=datetime.utcnow,
        index=True,
    )
