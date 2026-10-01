from sqlalchemy import Column, ForeignKey, Integer, String
from sqlalchemy.orm import relationship

from app.core.database import Base


class Department(Base):
    __tablename__ = "departments"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(200), nullable=False)
    code = Column(String(50), nullable=False)

    university_id = Column(
        Integer,
        ForeignKey("universities.id"),
        nullable=False,
    )

    university = relationship(
        "University",
        back_populates="departments",
    )

    students = relationship(
        "Student",
        back_populates="department",
    )