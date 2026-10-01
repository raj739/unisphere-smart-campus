from datetime import datetime
from pydantic import BaseModel, Field


class HostelBuildingCreateRequest(BaseModel):
    name: str = Field(min_length=2, max_length=200)
    code: str = Field(min_length=2, max_length=50)
    hostel_type: str = Field(default="general", max_length=50)
    gender: str | None = Field(default=None, max_length=30)
    address: str | None = Field(default=None, max_length=300)
    total_floors: int | None = Field(default=None, ge=1)


class HostelBuildingResponse(BaseModel):
    id: int
    name: str
    code: str
    hostel_type: str
    gender: str | None
    address: str | None
    total_floors: int | None
    is_active: bool


class HostelRoomCreateRequest(BaseModel):
    building_id: int
    room_number: str = Field(min_length=1, max_length=50)
    floor_number: int | None = Field(default=None, ge=0)
    room_type: str = Field(default="shared", max_length=50)
    capacity: int = Field(default=2, ge=1, le=20)


class HostelRoomResponse(BaseModel):
    id: int
    building_id: int
    room_number: str
    floor_number: int | None
    room_type: str
    capacity: int
    occupied_count: int
    status: str
    is_active: bool


class HostelAllocationCreateRequest(BaseModel):
    student_id: int
    room_id: int
    remarks: str | None = Field(default=None, max_length=1000)


class HostelAllocationResponse(BaseModel):
    id: int
    student_id: int
    room_id: int
    allocation_number: str
    status: str
    allocated_at: datetime
    check_in_at: datetime | None
    check_out_at: datetime | None
    remarks: str | None
    student_name: str | None = None
    student_uni_id: str | None = None
    student_programme: str | None = None
    building_id: int | None = None
    building_name: str | None = None
    building_code: str | None = None
    hostel_type: str | None = None
    room_number: str | None = None
    floor_number: int | None = None
    room_type: str | None = None
    room_capacity: int | None = None
    room_occupied_count: int | None = None
    room_status: str | None = None


class HostelAllocationStatusRequest(BaseModel):
    status: str = Field(min_length=2, max_length=50)


class HostelComplaintCreateRequest(BaseModel):
    category: str = Field(min_length=2, max_length=100)
    title: str = Field(min_length=2, max_length=250)
    description: str = Field(min_length=5, max_length=5000)
    priority: str = Field(default="normal", max_length=30)


class HostelComplaintResponse(BaseModel):
    id: int
    student_id: int
    room_id: int | None
    complaint_number: str
    category: str
    title: str
    description: str
    priority: str
    status: str
    resolution: str | None
    created_at: datetime
    resolved_at: datetime | None
    student_name: str | None = None
    student_uni_id: str | None = None
    building_name: str | None = None
    room_number: str | None = None


class HostelComplaintResolveRequest(BaseModel):
    resolution: str = Field(min_length=2, max_length=5000)
