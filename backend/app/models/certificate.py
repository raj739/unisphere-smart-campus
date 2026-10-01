from sqlalchemy import Column, ForeignKey, Integer, String
from sqlalchemy.orm import relationship

from app.core.database import Base


class Certificate(Base):
    __tablename__ = "certificates"

    id = Column(Integer, primary_key=True, index=True)
    student_id = Column(Integer, ForeignKey("students.id"), nullable=False)
    certificate_id = Column(String(100), unique=True, nullable=False, index=True)
    certificate_type = Column(String(100), nullable=False)
    title = Column(String(200), nullable=False)
    issue_date = Column(String(20), nullable=False)
    status = Column(String(50), nullable=False, default="Valid")
    verification_token = Column(String(200), unique=True, nullable=False)

    student = relationship("Student")
