from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field


class PermissionResponse(BaseModel):
    id: int
    code: str
    name: str
    description: str
    module: str
    is_active: bool
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class RolePermissionCreate(BaseModel):
    role: str = Field(min_length=1, max_length=100)
    permission_code: str = Field(min_length=1, max_length=150)


class UserPermissionCreate(BaseModel):
    user_id: int
    permission_code: str = Field(min_length=1, max_length=150)
    granted: bool = True


class PermissionCheckRequest(BaseModel):
    permission_code: str = Field(
        min_length=1,
        max_length=150,
    )


class PermissionCheckResponse(BaseModel):
    permission_code: str
    allowed: bool
