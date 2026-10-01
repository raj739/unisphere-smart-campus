from sqlalchemy import Boolean, Column, ForeignKey, Integer, String
from sqlalchemy.orm import relationship

from app.core.database import Base


class CourseOffering(Base):
    __tablename__ = "course_offerings"

    id = Column(Integer, primary_key=True, index=True)

    course_id = Column(
        Integer,
        ForeignKey("courses.id"),
        nullable=False,
    )

    semester_id = Column(
        Integer,
        ForeignKey("semesters.id"),
        nullable=False,
    )

    academic_session = Column(
        String(50),
        nullable=False,
    )

    section = Column(
        String(50),
        nullable=True,
    )

    faculty_name = Column(
        String(200),
        nullable=True,
    )

    capacity = Column(
        Integer,
        nullable=True,
    )

    is_active = Column(
        Boolean,
        nullable=False,
        default=True,
    )

    course = relationship("Course")
    semester = relationship("Semester")
