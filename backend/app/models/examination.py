from sqlalchemy import Column, ForeignKey, Integer, String

from app.core.database import Base


class Examination(Base):
    __tablename__ = "examinations"

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

    examination_name = Column(String(200), nullable=False)

    exam_date = Column(String(20), nullable=False)
    start_time = Column(String(10), nullable=False)
    end_time = Column(String(10), nullable=False)

    venue = Column(String(100), nullable=True)
    