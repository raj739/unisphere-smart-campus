from datetime import date

from sqlalchemy import Boolean, Column, Date, ForeignKey, Integer, String
from sqlalchemy.orm import relationship

from app.core.database import Base


class AttendanceSessionV2(Base):
    __tablename__ = "attendance_sessions_v2"

    id = Column(Integer, primary_key=True, index=True)

    course_offering_id = Column(
        Integer,
        ForeignKey("course_offerings.id"),
        nullable=False,
    )

    session_date = Column(
        Date,
        nullable=False,
    )

    start_time = Column(
        String(10),
        nullable=True,
    )

    end_time = Column(
        String(10),
        nullable=True,
    )

    topic = Column(
        String(300),
        nullable=True,
    )

    faculty_name = Column(
        String(200),
        nullable=True,
    )

    is_locked = Column(
        Boolean,
        nullable=False,
        default=False,
    )

    course_offering = relationship("CourseOffering")
