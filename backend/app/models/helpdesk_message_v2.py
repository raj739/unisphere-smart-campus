from datetime import datetime, timezone
from sqlalchemy import Column, DateTime, ForeignKey, Integer, String, Text
from sqlalchemy.orm import relationship
from app.core.database import Base

class HelpdeskMessageV2(Base):
    __tablename__ = "helpdesk_messages_v2"

    id = Column(Integer, primary_key=True, index=True)
    ticket_id = Column(Integer, ForeignKey("helpdesk_tickets_v2.id"), nullable=False, index=True)
    sender_user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    message = Column(Text, nullable=False)
    created_at = Column(DateTime, nullable=False, default=lambda: datetime.now(timezone.utc))

    ticket = relationship("HelpdeskTicketV2")
    sender = relationship("User")
