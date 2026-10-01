from sqlalchemy import Column, ForeignKey, Integer, String

from app.core.database import Base


class TimetableEntry(Base):
    __tablename__ = "timetable"

    id = Column(Integer, primary_key=True, index=True)

    course_id = Column(
        Integer,
        ForeignKey("courses.id"),
        nullable=False,
    )

    day_of_week = Column(String(20), nullable=False)

    start_time = Column(String(10), nullable=False)
    end_time = Column(String(10), nullable=False)

    faculty_name = Column(String(150), nullable=True)
    room = Column(String(50), nullable=True)

    session_type = Column(
        String(50),
        nullable=False,
        default="Lecture",
    )