from sqlalchemy import Boolean, Column, ForeignKey, Integer, String
from sqlalchemy.orm import relationship
from app.core.database import Base


class ExaminationScheduleV2(Base):
    __tablename__ = "examination_schedules_v2"

    id = Column(Integer, primary_key=True, index=True)
    examination_id = Column(
        Integer,
        ForeignKey("examinations_v2.id"),
        nullable=False,
    )
    course_id = Column(Integer, ForeignKey("courses.id"), nullable=False)
    exam_date = Column(String(20), nullable=False)
    start_time = Column(String(10), nullable=False)
    end_time = Column(String(10), nullable=False)
    room = Column(String(100), nullable=True)
    building = Column(String(150), nullable=True)
    max_marks = Column(Integer, nullable=False, default=100)
    passing_marks = Column(Integer, nullable=False, default=40)
    is_active = Column(Boolean, nullable=False, default=True)

    examination = relationship("ExaminationV2")
    course = relationship("Course")

