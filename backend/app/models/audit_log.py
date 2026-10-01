from datetime import datetime

from sqlalchemy import Boolean, Column, DateTime, Integer, JSON, String, Text

from app.core.database import Base


class AuditLog(Base):
    __tablename__ = "audit_logs"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, nullable=True, index=True)

    action = Column(String(100), nullable=False, index=True)
    module = Column(String(100), nullable=False, index=True)

    entity_type = Column(String(100), nullable=True, index=True)
    entity_id = Column(String(100), nullable=True, index=True)

    description = Column(Text, nullable=True)

    ip_address = Column(String(100), nullable=True)
    user_agent = Column(String(500), nullable=True)

    metadata_json = Column(JSON, nullable=True)

    success = Column(Boolean, nullable=False, default=True, index=True)

    created_at = Column(
        DateTime,
        nullable=False,
        default=datetime.utcnow,
        index=True,
    )
