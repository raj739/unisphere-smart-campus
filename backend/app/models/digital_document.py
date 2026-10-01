from datetime import datetime, timezone

from sqlalchemy import Boolean, Column, DateTime, ForeignKey, Integer, String
from sqlalchemy.orm import relationship

from app.core.database import Base


class DigitalDocument(Base):
    __tablename__ = "digital_documents"

    id = Column(Integer, primary_key=True, index=True)

    student_id = Column(
        Integer,
        ForeignKey("students.id"),
        nullable=False,
        index=True,
    )

    document_type = Column(String(50), nullable=False, index=True)
    document_number = Column(
        String(150),
        unique=True,
        nullable=False,
        index=True,
    )

    title = Column(String(250), nullable=False)

    issue_date = Column(String(20), nullable=False)
    valid_until = Column(String(20), nullable=True)

    status = Column(
        String(50),
        nullable=False,
        default="issued",
    )

    file_path = Column(String(500), nullable=True)
    file_hash = Column(String(128), nullable=True)

    verification_token = Column(
        String(200),
        unique=True,
        nullable=False,
        index=True,
    )

    qr_payload = Column(String(1000), nullable=True)

    issued_by_user_id = Column(
        Integer,
        ForeignKey("users.id"),
        nullable=False,
    )

    created_at = Column(
        DateTime,
        nullable=False,
        default=lambda: datetime.now(timezone.utc),
    )

    student = relationship("Student")
    issued_by = relationship("User")
