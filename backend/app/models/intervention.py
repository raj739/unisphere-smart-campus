from datetime import datetime, timezone

from sqlalchemy import Column, DateTime, ForeignKey, Integer, String, Text

from app.core.database import Base


class AcademicIntervention(Base):
    __tablename__ = "academic_interventions"

    id = Column(Integer, primary_key=True, index=True)

    student_id = Column(
        Integer,
        ForeignKey("students.id"),
        nullable=False,
    )

    warning_id = Column(
        Integer,
        ForeignKey("early_warnings.id"),
        nullable=True,
        index=True,
    )

    intervention_type = Column(
        String(100),
        nullable=False,
    )

    assigned_to = Column(
        String(150),
        nullable=True,
    )

    priority = Column(
        String(50),
        nullable=False,
        default="Medium",
    )

    reason = Column(
        Text,
        nullable=True,
    )

    notes = Column(Text, nullable=True)
    outcome = Column(Text, nullable=True)

    due_date = Column(
        String(20),
        nullable=True,
    )

    status = Column(
        String(50),
        nullable=False,
        default="Pending",
    )

    created_date = Column(
        String(20),
        nullable=False,
    )

    updated_at = Column(
        DateTime(timezone=True),
        nullable=False,
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
    )

# Backward-compatible model alias used by interventions_v2 API.
Intervention = AcademicIntervention
