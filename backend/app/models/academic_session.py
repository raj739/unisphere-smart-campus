from sqlalchemy import Boolean, Column, Integer, String

from app.core.database import Base


class AcademicSession(Base):
    __tablename__ = "academic_sessions"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(50), unique=True, nullable=False)
    start_year = Column(Integer, nullable=False)
    end_year = Column(Integer, nullable=False)
    is_active = Column(Boolean, nullable=False, default=True)
