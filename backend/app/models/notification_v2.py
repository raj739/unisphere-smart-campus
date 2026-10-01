from datetime import datetime, timezone
from sqlalchemy import Boolean, Column, DateTime, ForeignKey, Integer, String, Text
from sqlalchemy.orm import relationship
from app.core.database import Base

class NotificationV2(Base):
    __tablename__ = "notifications_v2"

    id = Column(Integer, primary_key=True, index=True)
    recipient_user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    template_id = Column(Integer, ForeignKey("notification_templates_v2.id"), nullable=True)
    category = Column(String(100), nullable=False)
    title = Column(String(250), nullable=False)
    message = Column(Text, nullable=False)
    priority = Column(String(30), nullable=False, default="normal")
    entity_type = Column(String(100), nullable=True)
    entity_id = Column(Integer, nullable=True)
    is_read = Column(Boolean, nullable=False, default=False)
    read_at = Column(DateTime, nullable=True)
    created_at = Column(DateTime, nullable=False, default=lambda: datetime.now(timezone.utc))
    expires_at = Column(DateTime, nullable=True)

    recipient = relationship("User")
    template = relationship("NotificationTemplateV2")
