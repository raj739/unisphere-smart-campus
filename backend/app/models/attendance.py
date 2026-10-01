from sqlalchemy import Column, ForeignKey, Integer, Float

from app.core.database import Base


class Attendance(Base):
    __tablename__ = "attendance"

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

    classes_held = Column(Integer, nullable=False, default=0)
    classes_attended = Column(Integer, nullable=False, default=0)

    percentage = Column(Float, nullable=False, default=0.0)