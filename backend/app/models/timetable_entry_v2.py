from sqlalchemy import Boolean, Column, ForeignKey, Integer, String
from sqlalchemy.orm import relationship

from app.core.database import Base


class TimetableEntryV2(Base):
    __tablename__ = "timetable_entries_v2"

    id = Column(Integer, primary_key=True, index=True)

    course_offering_id = Column(
        Integer,
        ForeignKey("course_offerings.id"),
        nullable=False,
    )

    day_of_week = Column(
        Integer,
        nullable=False,
    )

    start_time = Column(
        String(10),
        nullable=False,
    )

    end_time = Column(
        String(10),
        nullable=False,
    )

    room = Column(
        String(100),
        nullable=True,
    )

    building = Column(
        String(150),
        nullable=True,
    )

    faculty_name = Column(
        String(200),
        nullable=True,
    )

    is_active = Column(
        Boolean,
        nullable=False,
        default=True,
    )

    course_offering = relationship("CourseOffering")
