from datetime import datetime, timezone

from sqlalchemy import Column, DateTime, ForeignKey, Integer, String, Text
from sqlalchemy.orm import relationship

from app.core.database import Base


class StudentLifecycle(Base):
    __tablename__ = "student_lifecycle"

    id = Column(Integer, primary_key=True, index=True)
    student_id = Column(
        Integer,
        ForeignKey("students.id"),
        nullable=False,
        unique=True,
    )

    current_status = Column(
        String(50),
        nullable=False,
        default="active",
    )

    admission_date = Column(DateTime, nullable=True)
    graduation_date = Column(DateTime, nullable=True)
    alumni_date = Column(DateTime, nullable=True)

    admission_reference = Column(String(150), nullable=True)
    notes = Column(Text, nullable=True)

    updated_at = Column(
        DateTime,
        nullable=False,
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
    )

    student = relationship("Student")
