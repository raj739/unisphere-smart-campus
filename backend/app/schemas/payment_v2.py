from pydantic import BaseModel, Field


class PaymentInitiateRequest(BaseModel):
    invoice_id: int
    amount: float = Field(gt=0)
    payment_method: str = Field(
        default="online",
        min_length=2,
        max_length=50,
    )
    idempotency_key: str = Field(
        min_length=8,
        max_length=200,
    )


class PaymentTransactionResponse(BaseModel):
    id: int
    invoice_id: int
    student_id: int
    transaction_number: str
    gateway_transaction_id: str | None
    amount: float
    currency: str
    payment_method: str
    status: str
    gateway_name: str | None
    gateway_order_id: str | None
    failure_reason: str | None
    paid_at: str | None


class PaymentVerifyRequest(BaseModel):
    gateway_transaction_id: str = Field(
        min_length=2,
        max_length=200,
    )
    success: bool
    failure_reason: str | None = Field(
        default=None,
        max_length=500,
    )


class PaymentWebhookRequest(BaseModel):
    event_id: str = Field(
        min_length=5,
        max_length=200,
    )
    event_type: str = Field(
        min_length=2,
        max_length=100,
    )
    transaction_number: str | None = Field(
        default=None,
        max_length=120,
    )
    gateway_transaction_id: str | None = Field(
        default=None,
        max_length=200,
    )
    status: str = Field(
        min_length=2,
        max_length=40,
    )
    payload: str | None = None


class PaymentReceiptResponse(BaseModel):
    id: int
    payment_transaction_id: int
    receipt_number: str
    issued_at: str
    document_id: int | None
