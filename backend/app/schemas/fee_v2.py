from pydantic import BaseModel, ConfigDict, Field, model_validator


class FeeStructureCreateRequest(BaseModel):
    programme_id: int
    semester: int = Field(ge=1, le=20)
    academic_session: str = Field(min_length=4, max_length=50)
    fee_type: str = Field(min_length=2, max_length=100)
    amount: float = Field(ge=0)
    mandatory: bool = True


class FeeStructureResponse(BaseModel):
    id: int
    programme_id: int
    semester: int
    academic_session: str
    fee_type: str
    amount: float
    mandatory: bool
    is_active: bool


class InvoiceItemCreate(BaseModel):
    fee_type: str = Field(min_length=2, max_length=100)
    description: str | None = Field(default=None, max_length=250)
    amount: float = Field(ge=0)


class InvoiceCreateRequest(BaseModel):
    student_id: int
    academic_session: str = Field(min_length=4, max_length=50)
    semester: int = Field(ge=1, le=20)
    due_date: str | None = Field(default=None, max_length=20)
    items: list[InvoiceItemCreate] = Field(min_length=1)

    @model_validator(mode="after")
    def validate_positive_total(self):
        if sum(item.amount for item in self.items) <= 0:
            raise ValueError("Invoice total must be greater than zero")
        return self


class InvoiceItemResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    invoice_id: int
    fee_type: str
    description: str | None
    amount: float


class InvoiceResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    student_id: int
    academic_session: str
    semester: int
    invoice_number: str
    total_amount: float
    discount_amount: float
    waiver_amount: float
    paid_amount: float
    outstanding_amount: float
    due_date: str | None
    status: str
    items: list[InvoiceItemResponse]


class FeeAdjustmentRequest(BaseModel):
    adjustment_type: str = Field(min_length=2, max_length=50)
    amount: float = Field(gt=0)
    reason: str = Field(min_length=3, max_length=500)


class FeePaymentUpdateRequest(BaseModel):
    amount: float = Field(gt=0)
