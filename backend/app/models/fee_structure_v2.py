from sqlalchemy import Boolean, Column, Float, ForeignKey, Integer, String
from sqlalchemy.orm import relationship

from app.core.database import Base


class FeeStructure(Base):
    __tablename__ = "fee_structures_v2"

    id = Column(Integer, primary_key=True, index=True)

    programme_id = Column(
        Integer,
        ForeignKey("programmes.id"),
        nullable=False,
    )

    semester = Column(Integer, nullable=False)

    academic_session = Column(
        String(50),
        nullable=False,
    )

    fee_type = Column(
        String(100),
        nullable=False,
    )

    amount = Column(
        Float,
        nullable=False,
        default=0.0,
    )

    mandatory = Column(
        Boolean,
        nullable=False,
        default=True,
    )

    is_active = Column(
        Boolean,
        nullable=False,
        default=True,
    )

    programme = relationship("Programme")
