from datetime import datetime, timezone
from sqlalchemy import Column, DateTime, ForeignKey, Integer, String
from sqlalchemy.orm import relationship
from app.core.database import Base


class ExaminationRegistrationV2(Base):
    __tablename__ = "examination_registrations_v2"

    id = Column(Integer, primary_key=True, index=True)
    examination_id = Column(
        Integer,
        ForeignKey("examinations_v2.id"),
        nullable=False,
    )
    student_id = Column(
        Integer,
        ForeignKey("students.id"),
        nullable=False,
    )
    registration_number = Column(String(100), unique=True, nullable=False)
    status = Column(String(50), nullable=False, default="registered")
    registered_at = Column(
        DateTime,
        nullable=False,
        default=lambda: datetime.now(timezone.utc),
    )
    approved_at = Column(DateTime, nullable=True)
    approved_by_user_id = Column(Integer, ForeignKey("users.id"), nullable=True)

    examination = relationship("ExaminationV2")
    student = relationship("Student")
    approved_by = relationship("User")
