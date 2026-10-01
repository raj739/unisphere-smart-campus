from sqlalchemy import Column, Integer, String

from app.core.database import Base


class Semester(Base):
    __tablename__ = "semesters"

    id = Column(Integer, primary_key=True, index=True)

    number = Column(Integer, nullable=False)
    name = Column(String(100), nullable=False)

    academic_year = Column(String(50), nullable=True)