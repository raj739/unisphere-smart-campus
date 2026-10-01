from datetime import datetime, timezone
from sqlalchemy import Column, DateTime, ForeignKey, Integer, String, Text
from sqlalchemy.orm import relationship
from app.core.database import Base

class NotificationDeliveryV2(Base):
    __tablename__ = "notification_deliveries_v2"

    id = Column(Integer, primary_key=True, index=True)
    notification_id = Column(Integer, ForeignKey("notifications_v2.id"), nullable=False, index=True)
    channel = Column(String(30), nullable=False)
    status = Column(String(40), nullable=False, default="pending")
    provider = Column(String(100), nullable=True)
    provider_message_id = Column(String(200), nullable=True)
    error_message = Column(Text, nullable=True)
    attempted_at = Column(DateTime, nullable=True)
    created_at = Column(DateTime, nullable=False, default=lambda: datetime.now(timezone.utc))

    notification = relationship("NotificationV2")
