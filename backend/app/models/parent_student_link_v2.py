from datetime import datetime, timezone
from sqlalchemy import Boolean, Column, DateTime, ForeignKey, Integer, String
from sqlalchemy.orm import relationship
from app.core.database import Base

class ParentStudentLinkV2(Base):
    __tablename__ = "parent_student_links_v2"

    id = Column(Integer, primary_key=True, index=True)
    parent_user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    student_id = Column(Integer, ForeignKey("students.id"), nullable=False)
    relationship_type = Column(String(50), nullable=True)
    is_primary = Column(Boolean, nullable=False, default=False)
    is_active = Column(Boolean, nullable=False, default=True)
    linked_at = Column(DateTime, nullable=False, default=lambda: datetime.now(timezone.utc))

    parent_user = relationship("User")
    student = relationship("Student")
