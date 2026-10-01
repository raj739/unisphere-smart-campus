from datetime import datetime, timezone

from sqlalchemy import Column, DateTime, ForeignKey, Integer, String, Text

from app.core.database import Base


class PaymentEventV2(Base):
    __tablename__ = "payment_events_v2"

    id = Column(Integer, primary_key=True, index=True)

    payment_transaction_id = Column(
        Integer,
        ForeignKey("payment_transactions_v2.id"),
        nullable=True,
    )

    event_id = Column(
        String(200),
        unique=True,
        nullable=False,
        index=True,
    )

    event_type = Column(
        String(100),
        nullable=False,
    )

    gateway_name = Column(
        String(100),
        nullable=True,
    )

    payload = Column(
        Text,
        nullable=True,
    )

    processing_status = Column(
        String(40),
        nullable=False,
        default="received",
    )

    received_at = Column(
        DateTime,
        nullable=False,
        default=lambda: datetime.now(timezone.utc),
    )
