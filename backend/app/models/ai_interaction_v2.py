from datetime import datetime, timezone
from sqlalchemy import Column, DateTime, ForeignKey, Integer, String, Text
from sqlalchemy.orm import relationship
from app.core.database import Base


class AIInteractionV2(Base):
    __tablename__ = "ai_interactions_v2"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    student_id = Column(Integer, ForeignKey("students.id"), nullable=True, index=True)
    session_id = Column(String(150), nullable=True, index=True)
    user_message = Column(Text, nullable=False)
    ai_response = Column(Text, nullable=True)
    model_name = Column(String(150), nullable=True)
    context_type = Column(String(100), nullable=True)
    status = Column(String(40), nullable=False, default="completed")
    created_at = Column(
        DateTime,
        nullable=False,
        default=lambda: datetime.now(timezone.utc),
    )

    user = relationship("User")
    student = relationship("Student")
