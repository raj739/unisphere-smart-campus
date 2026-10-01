from sqlalchemy import Column, ForeignKey, Integer, Float, String

from app.core.database import Base


class Result(Base):
    __tablename__ = "results"

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

    grade = Column(String(10), nullable=False)
    grade_point = Column(Float, nullable=False)
    marks = Column(Float, nullable=True)
    marks = Column(Float, nullable=True)