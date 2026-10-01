from datetime import datetime
from pydantic import BaseModel, Field


class HelpdeskCategoryCreateRequest(BaseModel):
    name: str = Field(min_length=2, max_length=150)
    code: str = Field(min_length=2, max_length=50)
    description: str | None = Field(default=None, max_length=500)
    department: str | None = Field(default=None, max_length=150)


class HelpdeskCategoryResponse(BaseModel):
    id: int
    name: str
    code: str
    description: str | None
    department: str | None
    is_active: bool


class HelpdeskTicketCreateRequest(BaseModel):
    category_id: int
    subject: str = Field(min_length=3, max_length=250)
    description: str = Field(min_length=5, max_length=10000)
    priority: str = Field(default="normal", max_length=30)


class HelpdeskTicketResponse(BaseModel):
    id: int
    ticket_number: str
    student_id: int
    category_id: int
    subject: str
    description: str
    priority: str
    status: str
    assigned_to_user_id: int | None
    resolution: str | None
    created_at: datetime
    updated_at: datetime
    resolved_at: datetime | None


class HelpdeskTicketUpdateRequest(BaseModel):
    status: str | None = Field(default=None, max_length=50)
    priority: str | None = Field(default=None, max_length=30)
    assigned_to_user_id: int | None = None


class HelpdeskResolveRequest(BaseModel):
    resolution: str = Field(min_length=2, max_length=10000)


class HelpdeskMessageCreateRequest(BaseModel):
    message: str = Field(min_length=1, max_length=10000)


class HelpdeskMessageResponse(BaseModel):
    id: int
    ticket_id: int
    sender_user_id: int
    message: str
    created_at: datetime
