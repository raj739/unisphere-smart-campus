from datetime import datetime, timezone
from sqlalchemy import Boolean, Column, DateTime, Integer, String, Text
from app.core.database import Base

class NotificationTemplateV2(Base):
    __tablename__ = "notification_templates_v2"

    id = Column(Integer, primary_key=True, index=True)
    code = Column(String(100), unique=True, nullable=False, index=True)
    title_template = Column(String(250), nullable=False)
    message_template = Column(Text, nullable=False)
    category = Column(String(100), nullable=False)
    default_priority = Column(String(30), nullable=False, default="normal")
    is_active = Column(Boolean, nullable=False, default=True)
