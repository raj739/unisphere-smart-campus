from datetime import datetime, timezone

from sqlalchemy import Column, DateTime, ForeignKey, Integer, String

from app.core.database import Base


class DocumentVerificationLog(Base):
    __tablename__ = "document_verification_logs"

    id = Column(Integer, primary_key=True, index=True)

    document_id = Column(
        Integer,
        ForeignKey("digital_documents.id"),
        nullable=False,
    )

    verification_code = Column(
        String(150),
        nullable=False,
        index=True,
    )

    verification_result = Column(
        String(30),
        nullable=False,
    )

    verified_at = Column(
        DateTime,
        nullable=False,
        default=lambda: datetime.now(timezone.utc),
    )

    source = Column(
        String(50),
        nullable=False,
        default="public",
    )
