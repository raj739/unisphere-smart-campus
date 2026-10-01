from sqlalchemy import Boolean, Column, ForeignKey, Integer, String, UniqueConstraint
from sqlalchemy.orm import relationship

from app.core.database import Base


class ProgrammeSpecialization(Base):
    __tablename__ = "programme_specializations"
    __table_args__ = (
        UniqueConstraint(
            "programme_id",
            "name",
            name="uq_programme_specialization_name",
        ),
    )

    id = Column(Integer, primary_key=True, index=True)
    programme_id = Column(
        Integer,
        ForeignKey("programmes.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    name = Column(String(200), nullable=False)
    code = Column(String(50), nullable=False)
    is_active = Column(Boolean, nullable=False, default=True)

    programme = relationship("Programme", back_populates="specializations")
