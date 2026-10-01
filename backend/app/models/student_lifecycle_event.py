from datetime import datetime, timezone

from sqlalchemy import Column, DateTime, ForeignKey, Integer, String, Text
from sqlalchemy.orm import relationship

from app.core.database import Base


class StudentLifecycleEvent(Base):
    __tablename__ = "student_lifecycle_events"

    id = Column(Integer, primary_key=True, index=True)

    student_id = Column(
        Integer,
        ForeignKey("students.id"),
        nullable=False,
    )

    from_status = Column(String(50), nullable=True)
    to_status = Column(String(50), nullable=False)

    reason = Column(Text, nullable=True)

    changed_by_user_id = Column(
        Integer,
        ForeignKey("users.id"),
        nullable=False,
    )

    created_at = Column(
        DateTime,
        nullable=False,
        default=lambda: datetime.now(timezone.utc),
    )

    student = relationship("Student")
    changed_by = relationship("User")
