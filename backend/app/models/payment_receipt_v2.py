from datetime import datetime, timezone

from sqlalchemy import Column, DateTime, ForeignKey, Integer, String

from app.core.database import Base


class PaymentReceiptV2(Base):
    __tablename__ = "payment_receipts_v2"

    id = Column(Integer, primary_key=True, index=True)

    payment_transaction_id = Column(
        Integer,
        ForeignKey("payment_transactions_v2.id"),
        nullable=False,
        unique=True,
    )

    receipt_number = Column(
        String(120),
        unique=True,
        nullable=False,
        index=True,
    )

    issued_at = Column(
        DateTime,
        nullable=False,
        default=lambda: datetime.now(timezone.utc),
    )

    document_id = Column(
        Integer,
        ForeignKey("digital_documents.id"),
        nullable=True,
    )
