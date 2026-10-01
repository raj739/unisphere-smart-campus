from sqlalchemy import Column, ForeignKey, Integer, String
from sqlalchemy.orm import relationship

from app.core.database import Base


class Student(Base):
    __tablename__ = "students"

    id = Column(Integer, primary_key=True, index=True)

    user_id = Column(
        Integer,
        ForeignKey("users.id"),
        nullable=False,
        unique=True,
    )

    department_id = Column(
        Integer,
        ForeignKey("departments.id"),
        nullable=False,
    )

    programme_id = Column(Integer, ForeignKey("programmes.id"), nullable=True, index=True)
    specialization_id = Column(
        Integer,
        ForeignKey("programme_specializations.id"),
        nullable=True,
        index=True,
    )
    curriculum_id = Column(Integer, ForeignKey("curricula.id"), nullable=True, index=True)
    academic_session_id = Column(
        Integer,
        ForeignKey("academic_sessions.id"),
        nullable=True,
        index=True,
    )

    uni_id = Column(
        String(100),
        unique=True,
        nullable=False,
        index=True,
    )

    university_id = Column(String(100), nullable=True)
    enrollment_number = Column(String(100), unique=True, nullable=True)

    full_name = Column(String(200), nullable=False)
    programme = Column(String(150), nullable=False)
    current_semester = Column(Integer, nullable=False)

    academic_session = Column(String(50), nullable=True)

    user = relationship("User")
    department = relationship(
        "Department",
        back_populates="students",
    )
    programme_record = relationship("Programme")
    specialization = relationship("ProgrammeSpecialization")
    curriculum = relationship("Curriculum")
    academic_session_record = relationship("AcademicSession")
