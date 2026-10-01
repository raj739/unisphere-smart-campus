from datetime import datetime
from pydantic import BaseModel, Field


class TransportRouteCreateRequest(BaseModel):
    name: str = Field(min_length=2, max_length=200)
    code: str = Field(min_length=2, max_length=50)
    description: str | None = Field(default=None, max_length=500)


class TransportRouteResponse(BaseModel):
    id: int
    name: str
    code: str
    description: str | None
    is_active: bool


class TransportStopCreateRequest(BaseModel):
    route_id: int
    name: str = Field(min_length=2, max_length=200)
    sequence_number: int = Field(ge=1)
    pickup_time: str | None = Field(default=None, max_length=20)
    landmark: str | None = Field(default=None, max_length=300)


class TransportStopResponse(BaseModel):
    id: int
    route_id: int
    name: str
    sequence_number: int
    pickup_time: str | None
    landmark: str | None
    is_active: bool


class TransportVehicleCreateRequest(BaseModel):
    vehicle_number: str = Field(min_length=2, max_length=50)
    vehicle_type: str = Field(default="bus", max_length=50)
    capacity: int = Field(default=40, ge=1, le=200)
    driver_name: str | None = Field(default=None, max_length=200)
    driver_contact: str | None = Field(default=None, max_length=30)


class TransportVehicleResponse(BaseModel):
    id: int
    vehicle_number: str
    vehicle_type: str
    capacity: int
    driver_name: str | None
    driver_contact: str | None
    status: str
    is_active: bool


class TransportAssignmentCreateRequest(BaseModel):
    route_id: int
    vehicle_id: int
    academic_session: str = Field(min_length=4, max_length=50)


class TransportAssignmentResponse(BaseModel):
    id: int
    route_id: int
    vehicle_id: int
    academic_session: str
    status: str
    is_active: bool


class StudentTransportAllocationCreateRequest(BaseModel):
    student_id: int
    route_id: int
    stop_id: int
    academic_session: str = Field(min_length=4, max_length=50)
    remarks: str | None = Field(default=None, max_length=1000)


class StudentTransportAllocationResponse(BaseModel):
    id: int
    student_id: int
    route_id: int
    stop_id: int
    allocation_number: str
    academic_session: str
    status: str
    allocated_at: datetime
    deactivated_at: datetime | None
    remarks: str | None
    student_name: str | None = None
    student_uni_id: str | None = None
    student_programme: str | None = None
    route_name: str | None = None
    route_code: str | None = None
    stop_name: str | None = None
    stop_sequence: int | None = None
    pickup_time: str | None = None
    landmark: str | None = None
    vehicle_number: str | None = None
    vehicle_type: str | None = None
    vehicle_capacity: int | None = None
    driver_name: str | None = None
    driver_contact: str | None = None


class TransportAllocationStatusRequest(BaseModel):
    status: str = Field(min_length=2, max_length=50)


class TransportIssueCreateRequest(BaseModel):
    category: str = Field(min_length=2, max_length=100)
    title: str = Field(min_length=2, max_length=250)
    description: str = Field(min_length=5, max_length=5000)
    priority: str = Field(default="normal", max_length=30)


class TransportIssueResponse(BaseModel):
    id: int
    student_id: int
    allocation_id: int | None
    issue_number: str
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


class TransportIssueResolveRequest(BaseModel):
    resolution: str = Field(min_length=2, max_length=5000)
