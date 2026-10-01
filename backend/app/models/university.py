from sqlalchemy import Column, Integer, String
from sqlalchemy.orm import relationship

from app.core.database import Base


class University(Base):
    __tablename__ = "universities"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(200), nullable=False)
    code = Column(String(50), unique=True, nullable=False)
    city = Column(String(100), nullable=True)
    state = Column(String(100), nullable=True)

    departments = relationship(
        "Department",
        back_populates="university",
        cascade="all, delete-orphan",
    )
    