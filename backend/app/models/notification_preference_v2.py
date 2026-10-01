from datetime import datetime, timezone
from sqlalchemy import Boolean, Column, DateTime, ForeignKey, Integer, String
from sqlalchemy.orm import relationship
from app.core.database import Base

class NotificationPreferenceV2(Base):
    __tablename__ = "notification_preferences_v2"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, unique=True)
    in_app_enabled = Column(Boolean, nullable=False, default=True)
    email_enabled = Column(Boolean, nullable=False, default=True)
    sms_enabled = Column(Boolean, nullable=False, default=False)
    push_enabled = Column(Boolean, nullable=False, default=True)
    academic_enabled = Column(Boolean, nullable=False, default=True)
    fee_enabled = Column(Boolean, nullable=False, default=True)
    examination_enabled = Column(Boolean, nullable=False, default=True)
    service_enabled = Column(Boolean, nullable=False, default=True)
    system_enabled = Column(Boolean, nullable=False, default=True)
    updated_at = Column(DateTime, nullable=False, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))

    user = relationship("User")
