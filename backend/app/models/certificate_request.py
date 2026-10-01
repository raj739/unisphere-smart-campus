from datetime import datetime, timezone

from sqlalchemy import Column, DateTime, ForeignKey, Integer, String, Text
from sqlalchemy.orm import relationship

from app.core.database import Base


class CertificateRequest(Base):
    __tablename__ = "certificate_requests"

    id = Column(Integer, primary_key=True, index=True)
    request_number = Column(String(120), unique=True, nullable=False, index=True)
    student_id = Column(Integer, ForeignKey("students.id"), nullable=False, index=True)
    certificate_type = Column(String(100), nullable=False, index=True)
    purpose = Column(Text, nullable=False)
    delivery_mode = Column(String(30), nullable=False, default="digital")
    status = Column(String(30), nullable=False, default="submitted", index=True)
    requested_at = Column(
        DateTime(timezone=True),
        nullable=False,
        default=lambda: datetime.now(timezone.utc),
    )
    reviewed_at = Column(DateTime(timezone=True), nullable=True)
    reviewed_by_user_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    review_remarks = Column(Text, nullable=True)
    rejection_reason = Column(Text, nullable=True)
    certificate_id = Column(Integer, ForeignKey("certificates.id"), nullable=True, unique=True)

    student = relationship("Student")
    reviewed_by = relationship("User")
    certificate = relationship("Certificate")
