from datetime import datetime, timezone
from sqlalchemy import Column, DateTime, ForeignKey, Integer, String, Text
from sqlalchemy.orm import relationship
from app.core.database import Base

class HelpdeskTicketV2(Base):
    __tablename__ = "helpdesk_tickets_v2"

    id = Column(Integer, primary_key=True, index=True)
    ticket_number = Column(String(120), unique=True, nullable=False, index=True)
    student_id = Column(Integer, ForeignKey("students.id"), nullable=False, index=True)
    category_id = Column(Integer, ForeignKey("helpdesk_categories_v2.id"), nullable=False)
    subject = Column(String(250), nullable=False)
    description = Column(Text, nullable=False)
    priority = Column(String(30), nullable=False, default="normal")
    status = Column(String(50), nullable=False, default="open")
    assigned_to_user_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    resolution = Column(Text, nullable=True)
    created_at = Column(DateTime, nullable=False, default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime, nullable=False, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))
    resolved_at = Column(DateTime, nullable=True)

    student = relationship("Student")
    category = relationship("HelpdeskCategoryV2")
    assigned_to = relationship("User")
