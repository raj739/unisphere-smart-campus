from datetime import datetime, timezone

from sqlalchemy import Column, DateTime, ForeignKey, Integer, String, Text
from sqlalchemy.orm import relationship

from app.core.database import Base


class DocumentEvent(Base):
    __tablename__ = "document_events"

    id = Column(Integer, primary_key=True, index=True)

    document_id = Column(
        Integer,
        ForeignKey("digital_documents.id"),
        nullable=False,
        index=True,
    )

    event_type = Column(String(50), nullable=False)

    performed_by_user_id = Column(
        Integer,
        ForeignKey("users.id"),
        nullable=True,
    )

    details = Column(Text, nullable=True)

    created_at = Column(
        DateTime,
        nullable=False,
        default=lambda: datetime.now(timezone.utc),
    )

    document = relationship("DigitalDocument")
    performed_by = relationship("User")
