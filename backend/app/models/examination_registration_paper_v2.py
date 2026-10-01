from sqlalchemy import Column, ForeignKey, Integer, String
from sqlalchemy.orm import relationship
from app.core.database import Base


class ExaminationRegistrationPaperV2(Base):
    __tablename__ = "examination_registration_papers_v2"

    id = Column(Integer, primary_key=True, index=True)
    registration_id = Column(
        Integer,
        ForeignKey("examination_registrations_v2.id"),
        nullable=False,
    )
    schedule_id = Column(
        Integer,
        ForeignKey("examination_schedules_v2.id"),
        nullable=False,
    )
    status = Column(String(50), nullable=False, default="registered")

    registration = relationship("ExaminationRegistrationV2")
    schedule = relationship("ExaminationScheduleV2")
