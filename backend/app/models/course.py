from sqlalchemy import Column, Integer, String

from app.core.database import Base


class Course(Base):
    __tablename__ = "courses"

    id = Column(Integer, primary_key=True, index=True)

    code = Column(String(50), unique=True, nullable=False)
    name = Column(String(200), nullable=False)

    credits = Column(Integer, nullable=False, default=0)

    department_id = Column(Integer, nullable=True)