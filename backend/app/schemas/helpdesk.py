from pydantic import BaseModel


class HelpdeskCreateRequest(BaseModel):
    subject: str
    description: str
    category: str
    priority: str = "Medium"


class HelpdeskTicketResponse(BaseModel):
    ticket_number: str
    subject: str
    description: str | None
    category: str
    priority: str
    status: str
    created_date: str
    assigned_to: str | None
