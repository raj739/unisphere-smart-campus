from sqlalchemy import Boolean, Column, ForeignKey, Integer, String
from sqlalchemy.orm import relationship

from app.core.database import Base


class Programme(Base):
    __tablename__ = "programmes"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(200), nullable=False)
    code = Column(String(50), nullable=False)
    department_id = Column(
        Integer,
        ForeignKey("departments.id"),
        nullable=False,
    )
    duration_years = Column(Integer, nullable=False, default=3)
    category = Column(String(100), nullable=True, index=True)
    is_active = Column(Boolean, nullable=False, default=True)

    department = relationship("Department")
    specializations = relationship(
        "ProgrammeSpecialization",
        back_populates="programme",
        cascade="all, delete-orphan",
        order_by="ProgrammeSpecialization.name",
    )
    curricula = relationship(
        "Curriculum",
        back_populates="programme",
        cascade="all, delete-orphan",
    )
