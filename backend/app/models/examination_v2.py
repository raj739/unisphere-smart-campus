from datetime import datetime, timezone
from sqlalchemy import Boolean, Column, DateTime, ForeignKey, Integer, String
from sqlalchemy.orm import relationship
from app.core.database import Base


class ExaminationV2(Base):
    __tablename__ = "examinations_v2"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(250), nullable=False)
    exam_type = Column(String(50), nullable=False, default="semester")
    academic_session = Column(String(50), nullable=False)
    semester_id = Column(Integer, ForeignKey("semesters.id"), nullable=False)
    start_date = Column(String(20), nullable=True)
    end_date = Column(String(20), nullable=True)
    registration_start = Column(String(20), nullable=True)
    registration_end = Column(String(20), nullable=True)
    is_registration_open = Column(Boolean, nullable=False, default=True)
    is_locked = Column(Boolean, nullable=False, default=False)
    created_at = Column(
        DateTime,
        nullable=False,
        default=lambda: datetime.now(timezone.utc),
    )

    semester = relationship("Semester")
