from sqlalchemy import Column, ForeignKey, Integer
from sqlalchemy.orm import relationship

from app.core.database import Base


class StudentCourse(Base):
    __tablename__ = "student_courses"

    id = Column(Integer, primary_key=True, index=True)

    student_id = Column(
        Integer,
        ForeignKey("students.id"),
        nullable=False,
    )

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

    student = relationship("Student")
    course = relationship("Course")
    semester = relationship("Semester")