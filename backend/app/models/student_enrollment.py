from datetime import datetime, timezone

from sqlalchemy import Column, DateTime, ForeignKey, Integer, String
from sqlalchemy.orm import relationship

from app.core.database import Base


class StudentEnrollment(Base):
    __tablename__ = "student_enrollments"

    id = Column(Integer, primary_key=True, index=True)

    student_id = Column(
        Integer,
        ForeignKey("students.id"),
        nullable=False,
    )

    course_offering_id = Column(
        Integer,
        ForeignKey("course_offerings.id"),
        nullable=False,
    )

    status = Column(
        String(50),
        nullable=False,
        default="enrolled",
    )

    enrolled_at = Column(
        DateTime,
        nullable=False,
        default=lambda: datetime.now(timezone.utc),
    )

    dropped_at = Column(
        DateTime,
        nullable=True,
    )

    student = relationship("Student")
    course_offering = relationship("CourseOffering")
