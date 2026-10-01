from datetime import datetime, timezone

from sqlalchemy import Boolean, Column, DateTime, ForeignKey, Integer, String, Text, UniqueConstraint
from sqlalchemy.orm import relationship

from app.core.database import Base


class Curriculum(Base):
    __tablename__ = "curricula"
    __table_args__ = (
        UniqueConstraint("catalog_key", "version", name="uq_curriculum_catalog_version"),
    )

    id = Column(Integer, primary_key=True, index=True)
    catalog_key = Column(String(250), nullable=False, index=True)
    programme_id = Column(Integer, ForeignKey("programmes.id"), nullable=False, index=True)
    specialization_id = Column(
        Integer,
        ForeignKey("programme_specializations.id"),
        nullable=True,
        index=True,
    )
    academic_session_id = Column(
        Integer,
        ForeignKey("academic_sessions.id"),
        nullable=True,
        index=True,
    )
    name = Column(String(300), nullable=False)
    version = Column(String(50), nullable=False)
    status = Column(String(30), nullable=False, default="draft", index=True)
    is_demo = Column(Boolean, nullable=False, default=False, index=True)
    source_name = Column(String(300), nullable=True)
    disclaimer = Column(Text, nullable=True)
    created_at = Column(
        DateTime(timezone=True),
        nullable=False,
        default=lambda: datetime.now(timezone.utc),
    )
    updated_at = Column(
        DateTime(timezone=True),
        nullable=False,
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
    )

    programme = relationship("Programme", back_populates="curricula")
    specialization = relationship("ProgrammeSpecialization")
    academic_session = relationship("AcademicSession")
    courses = relationship(
        "CurriculumCourse",
        back_populates="curriculum",
        cascade="all, delete-orphan",
        order_by="(CurriculumCourse.semester_number, CurriculumCourse.display_order)",
    )
