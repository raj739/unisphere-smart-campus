from pydantic import BaseModel


class UniversityOverviewResponse(BaseModel):
    total_users: int
    students: int
    parents: int
    administrators: int
    active_users: int


class RoleDistributionItem(BaseModel):
    role: str
    count: int


class SystemHealthResponse(BaseModel):
    database: str
    total_users: int
    active_users: int
    active_user_percentage: float
