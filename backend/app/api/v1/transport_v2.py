from datetime import datetime, timezone
from uuid import uuid4

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session, joinedload, selectinload

from app.core.database import get_db
from app.core.dependencies import get_current_user, require_role
from app.models.student import Student
from app.models.transport_route_v2 import TransportRouteV2
from app.models.transport_stop_v2 import TransportStopV2
from app.models.transport_vehicle_v2 import TransportVehicleV2
from app.models.transport_route_assignment_v2 import TransportRouteAssignmentV2
from app.models.student_transport_allocation_v2 import StudentTransportAllocationV2
from app.models.transport_issue_v2 import TransportIssueV2

from app.schemas.transport_v2 import (
    TransportRouteCreateRequest,
    TransportRouteResponse,
    TransportStopCreateRequest,
    TransportStopResponse,
    TransportVehicleCreateRequest,
    TransportVehicleResponse,
    TransportAssignmentCreateRequest,
    TransportAssignmentResponse,
    StudentTransportAllocationCreateRequest,
    StudentTransportAllocationResponse,
    TransportAllocationStatusRequest,
    TransportIssueCreateRequest,
    TransportIssueResponse,
    TransportIssueResolveRequest,
)

router = APIRouter(prefix="/transport-v2", tags=["Transport V2"])

ALLOCATION_STATUSES = {
    "active",
    "inactive",
    "cancelled",
}

ISSUE_PRIORITIES = {
    "low",
    "normal",
    "high",
    "urgent",
}


def get_student_by_user(db: Session, user_id: int):
    student = db.query(Student).filter(Student.user_id == user_id).first()

    if student is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Student profile not found",
        )

    return student


def active_assignment_map(db: Session):
    assignments = (
        db.query(TransportRouteAssignmentV2)
        .options(
            joinedload(TransportRouteAssignmentV2.route),
            joinedload(TransportRouteAssignmentV2.vehicle),
        )
        .filter(TransportRouteAssignmentV2.is_active == True)
        .order_by(TransportRouteAssignmentV2.id.desc())
        .all()
    )
    result = {}
    for assignment in assignments:
        result.setdefault(
            (assignment.route_id, assignment.academic_session),
            assignment,
        )
    return result


def transport_allocation_query(db: Session):
    return db.query(StudentTransportAllocationV2).options(
        joinedload(StudentTransportAllocationV2.student),
        joinedload(StudentTransportAllocationV2.route),
        joinedload(StudentTransportAllocationV2.stop),
    )


def allocation_payload(
    allocation: StudentTransportAllocationV2,
    assignments,
):
    student = allocation.student
    route = allocation.route
    stop = allocation.stop
    assignment = assignments.get(
        (allocation.route_id, allocation.academic_session)
    )
    vehicle = assignment.vehicle if assignment else None
    return {
        "id": allocation.id,
        "student_id": allocation.student_id,
        "route_id": allocation.route_id,
        "stop_id": allocation.stop_id,
        "allocation_number": allocation.allocation_number,
        "academic_session": allocation.academic_session,
        "status": allocation.status,
        "allocated_at": allocation.allocated_at,
        "deactivated_at": allocation.deactivated_at,
        "remarks": allocation.remarks,
        "student_name": student.full_name if student else None,
        "student_uni_id": (
            student.university_id or student.uni_id if student else None
        ),
        "student_programme": student.programme if student else None,
        "route_name": route.name if route else None,
        "route_code": route.code if route else None,
        "stop_name": stop.name if stop else None,
        "stop_sequence": stop.sequence_number if stop else None,
        "pickup_time": stop.pickup_time if stop else None,
        "landmark": stop.landmark if stop else None,
        "vehicle_number": vehicle.vehicle_number if vehicle else None,
        "vehicle_type": vehicle.vehicle_type if vehicle else None,
        "vehicle_capacity": vehicle.capacity if vehicle else None,
        "driver_name": vehicle.driver_name if vehicle else None,
        "driver_contact": vehicle.driver_contact if vehicle else None,
    }


def issue_query(db: Session):
    return db.query(TransportIssueV2).options(
        joinedload(TransportIssueV2.student)
    )


def issue_payload(issue: TransportIssueV2):
    student = issue.student
    return {
        "id": issue.id,
        "student_id": issue.student_id,
        "allocation_id": issue.allocation_id,
        "issue_number": issue.issue_number,
        "category": issue.category,
        "title": issue.title,
        "description": issue.description,
        "priority": issue.priority,
        "status": issue.status,
        "resolution": issue.resolution,
        "created_at": issue.created_at,
        "resolved_at": issue.resolved_at,
        "student_name": student.full_name if student else None,
        "student_uni_id": (
            student.university_id or student.uni_id if student else None
        ),
    }


@router.post(
    "/routes",
    response_model=TransportRouteResponse,
    dependencies=[Depends(require_role("admin"))],
)
def create_route(
    request: TransportRouteCreateRequest,
    db: Session = Depends(get_db),
):
    existing = (
        db.query(TransportRouteV2)
        .filter(TransportRouteV2.code == request.code)
        .first()
    )

    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Transport route code already exists",
        )

    route = TransportRouteV2(**request.model_dump())
    db.add(route)
    db.commit()
    db.refresh(route)

    return route


@router.get(
    "/routes",
    response_model=list[TransportRouteResponse],
)
def list_routes(
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return (
        db.query(TransportRouteV2)
        .filter(TransportRouteV2.is_active == True)
        .order_by(TransportRouteV2.name)
        .all()
    )


@router.post(
    "/stops",
    response_model=TransportStopResponse,
    dependencies=[Depends(require_role("admin"))],
)
def create_stop(
    request: TransportStopCreateRequest,
    db: Session = Depends(get_db),
):
    route = (
        db.query(TransportRouteV2)
        .filter(TransportRouteV2.id == request.route_id)
        .first()
    )

    if route is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Transport route not found",
        )

    existing = (
        db.query(TransportStopV2)
        .filter(
            TransportStopV2.route_id == request.route_id,
            TransportStopV2.sequence_number == request.sequence_number,
        )
        .first()
    )

    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Stop sequence already exists on this route",
        )

    stop = TransportStopV2(**request.model_dump())
    db.add(stop)
    db.commit()
    db.refresh(stop)

    return stop


@router.get(
    "/routes/{route_id}/stops",
    response_model=list[TransportStopResponse],
)
def route_stops(
    route_id: int,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    route = (
        db.query(TransportRouteV2)
        .filter(TransportRouteV2.id == route_id)
        .first()
    )

    if route is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Transport route not found",
        )

    return (
        db.query(TransportStopV2)
        .filter(
            TransportStopV2.route_id == route_id,
            TransportStopV2.is_active == True,
        )
        .order_by(TransportStopV2.sequence_number)
        .all()
    )


@router.post(
    "/vehicles",
    response_model=TransportVehicleResponse,
    dependencies=[Depends(require_role("admin"))],
)
def create_vehicle(
    request: TransportVehicleCreateRequest,
    db: Session = Depends(get_db),
):
    existing = (
        db.query(TransportVehicleV2)
        .filter(
            TransportVehicleV2.vehicle_number == request.vehicle_number
        )
        .first()
    )

    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Vehicle number already exists",
        )

    vehicle = TransportVehicleV2(**request.model_dump())
    db.add(vehicle)
    db.commit()
    db.refresh(vehicle)

    return vehicle


@router.get(
    "/vehicles",
    response_model=list[TransportVehicleResponse],
)
def list_vehicles(
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return (
        db.query(TransportVehicleV2)
        .filter(TransportVehicleV2.is_active == True)
        .order_by(TransportVehicleV2.vehicle_number)
        .all()
    )


@router.post(
    "/assignments",
    response_model=TransportAssignmentResponse,
    dependencies=[Depends(require_role("admin"))],
)
def create_assignment(
    request: TransportAssignmentCreateRequest,
    db: Session = Depends(get_db),
):
    route = (
        db.query(TransportRouteV2)
        .filter(TransportRouteV2.id == request.route_id)
        .first()
    )

    if route is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Transport route not found",
        )

    vehicle = (
        db.query(TransportVehicleV2)
        .filter(TransportVehicleV2.id == request.vehicle_id)
        .first()
    )

    if vehicle is None or not vehicle.is_active:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Active vehicle not found",
        )

    existing = (
        db.query(TransportRouteAssignmentV2)
        .filter(
            TransportRouteAssignmentV2.route_id == request.route_id,
            TransportRouteAssignmentV2.academic_session == request.academic_session,
            TransportRouteAssignmentV2.is_active == True,
        )
        .first()
    )

    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Route already has an active vehicle assignment",
        )

    assignment = TransportRouteAssignmentV2(
        **request.model_dump(),
        status="active",
        is_active=True,
    )

    vehicle.status = "assigned"

    db.add(assignment)
    db.commit()
    db.refresh(assignment)

    return assignment


@router.get(
    "/assignments",
    response_model=list[TransportAssignmentResponse],
    dependencies=[Depends(require_role("admin"))],
)
def list_assignments(
    db: Session = Depends(get_db),
):
    return (
        db.query(TransportRouteAssignmentV2)
        .filter(TransportRouteAssignmentV2.is_active == True)
        .order_by(TransportRouteAssignmentV2.id.desc())
        .all()
    )


@router.post(
    "/allocations",
    response_model=StudentTransportAllocationResponse,
    dependencies=[Depends(require_role("admin"))],
)
def create_student_allocation(
    request: StudentTransportAllocationCreateRequest,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    student = (
        db.query(Student)
        .filter(Student.id == request.student_id)
        .first()
    )

    if student is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Student not found",
        )

    route = (
        db.query(TransportRouteV2)
        .filter(
            TransportRouteV2.id == request.route_id,
            TransportRouteV2.is_active == True,
        )
        .first()
    )

    if route is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Active transport route not found",
        )

    stop = (
        db.query(TransportStopV2)
        .filter(
            TransportStopV2.id == request.stop_id,
            TransportStopV2.route_id == request.route_id,
            TransportStopV2.is_active == True,
        )
        .first()
    )

    if stop is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Stop does not belong to this route",
        )

    existing = (
        db.query(StudentTransportAllocationV2)
        .filter(
            StudentTransportAllocationV2.student_id == request.student_id,
            StudentTransportAllocationV2.academic_session == request.academic_session,
            StudentTransportAllocationV2.status == "active",
        )
        .first()
    )

    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Student already has active transport allocation",
        )

    assignment = (
        db.query(TransportRouteAssignmentV2)
        .options(joinedload(TransportRouteAssignmentV2.vehicle))
        .filter(
            TransportRouteAssignmentV2.route_id == request.route_id,
            TransportRouteAssignmentV2.academic_session == request.academic_session,
            TransportRouteAssignmentV2.is_active == True,
        )
        .first()
    )
    if assignment is None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Assign a vehicle to this route and academic session first",
        )

    active_count = (
        db.query(StudentTransportAllocationV2)
        .filter(
            StudentTransportAllocationV2.route_id == request.route_id,
            StudentTransportAllocationV2.academic_session == request.academic_session,
            StudentTransportAllocationV2.status == "active",
        )
        .count()
    )
    if active_count >= assignment.vehicle.capacity:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="The assigned vehicle is full",
        )

    allocation = StudentTransportAllocationV2(
        student_id=request.student_id,
        route_id=request.route_id,
        stop_id=request.stop_id,
        allocation_number=f"TA-{uuid4().hex[:12].upper()}",
        academic_session=request.academic_session,
        status="active",
        remarks=request.remarks,
        allocated_by_user_id=current_user.id,
    )

    db.add(allocation)
    db.commit()
    db.refresh(allocation)

    allocation = transport_allocation_query(db).filter(
        StudentTransportAllocationV2.id == allocation.id
    ).first()
    return allocation_payload(
        allocation,
        {(assignment.route_id, assignment.academic_session): assignment},
    )


@router.get(
    "/allocations",
    response_model=list[StudentTransportAllocationResponse],
    dependencies=[Depends(require_role("admin"))],
)
def list_student_allocations(
    db: Session = Depends(get_db),
):
    allocations = (
        transport_allocation_query(db)
        .order_by(StudentTransportAllocationV2.allocated_at.desc())
        .all()
    )
    assignments = active_assignment_map(db)
    return [allocation_payload(item, assignments) for item in allocations]


@router.get(
    "/me",
    response_model=list[StudentTransportAllocationResponse],
)
def my_transport(
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    student = get_student_by_user(db, current_user.id)

    allocations = (
        transport_allocation_query(db)
        .filter(StudentTransportAllocationV2.student_id == student.id)
        .order_by(StudentTransportAllocationV2.allocated_at.desc())
        .all()
    )
    assignments = active_assignment_map(db)
    return [allocation_payload(item, assignments) for item in allocations]


@router.get(
    "/admin/overview",
    dependencies=[Depends(require_role("admin"))],
)
def admin_overview(db: Session = Depends(get_db)):
    routes = (
        db.query(TransportRouteV2)
        .options(selectinload(TransportRouteV2.stops))
        .filter(TransportRouteV2.is_active == True)
        .order_by(TransportRouteV2.name)
        .all()
    )
    vehicles = (
        db.query(TransportVehicleV2)
        .filter(TransportVehicleV2.is_active == True)
        .order_by(TransportVehicleV2.vehicle_number)
        .all()
    )
    assignments = active_assignment_map(db)
    assignment_rows = sorted(
        assignments.values(),
        key=lambda item: item.id,
        reverse=True,
    )
    allocations = transport_allocation_query(db).order_by(
        StudentTransportAllocationV2.allocated_at.desc()
    ).all()
    issues = issue_query(db).order_by(
        TransportIssueV2.created_at.desc()
    ).all()

    active_counts = {}
    for item in allocations:
        if item.status == "active":
            key = (item.route_id, item.academic_session)
            active_counts[key] = active_counts.get(key, 0) + 1

    latest_by_route = {}
    assignment_by_vehicle = {}
    for item in assignment_rows:
        latest_by_route.setdefault(item.route_id, item)
        assignment_by_vehicle.setdefault(item.vehicle_id, item)

    route_rows = []
    for route in routes:
        assignment = latest_by_route.get(route.id)
        vehicle = assignment.vehicle if assignment else None
        passenger_count = active_counts.get(
            (route.id, assignment.academic_session), 0
        ) if assignment else 0
        stops = sorted(
            [stop for stop in route.stops if stop.is_active],
            key=lambda item: item.sequence_number,
        )
        route_rows.append({
            "id": route.id,
            "name": route.name,
            "code": route.code,
            "description": route.description,
            "stop_count": len(stops),
            "stops": [{
                "id": stop.id,
                "name": stop.name,
                "sequence_number": stop.sequence_number,
                "pickup_time": stop.pickup_time,
                "landmark": stop.landmark,
            } for stop in stops],
            "academic_session": assignment.academic_session if assignment else None,
            "vehicle_number": vehicle.vehicle_number if vehicle else None,
            "vehicle_id": vehicle.id if vehicle else None,
            "driver_name": vehicle.driver_name if vehicle else None,
            "driver_contact": vehicle.driver_contact if vehicle else None,
            "capacity": vehicle.capacity if vehicle else 0,
            "passenger_count": passenger_count,
            "available_seats": max(0, vehicle.capacity - passenger_count)
            if vehicle else 0,
        })

    vehicle_rows = []
    for vehicle in vehicles:
        assignment = assignment_by_vehicle.get(vehicle.id)
        passenger_count = active_counts.get(
            (assignment.route_id, assignment.academic_session), 0
        ) if assignment else 0
        vehicle_rows.append({
            "id": vehicle.id,
            "vehicle_number": vehicle.vehicle_number,
            "vehicle_type": vehicle.vehicle_type,
            "capacity": vehicle.capacity,
            "driver_name": vehicle.driver_name,
            "driver_contact": vehicle.driver_contact,
            "status": vehicle.status,
            "route_name": assignment.route.name if assignment else None,
            "route_code": assignment.route.code if assignment else None,
            "academic_session": assignment.academic_session if assignment else None,
            "passenger_count": passenger_count,
            "available_seats": max(0, vehicle.capacity - passenger_count),
        })

    operating_seats = sum(item["capacity"] for item in route_rows)
    allocated_seats = sum(item["passenger_count"] for item in route_rows)
    return {
        "metrics": {
            "route_count": len(route_rows),
            "vehicle_count": len(vehicle_rows),
            "operating_seats": operating_seats,
            "allocated_students": allocated_seats,
            "available_seats": max(0, operating_seats - allocated_seats),
            "open_issues": len([
                item for item in issues
                if item.status in {"open", "in_progress"}
            ]),
        },
        "routes": route_rows,
        "vehicles": vehicle_rows,
        "allocations": [
            allocation_payload(item, assignments) for item in allocations
        ],
        "issues": [issue_payload(item) for item in issues],
    }


@router.get(
    "/students/{student_id}",
    response_model=list[StudentTransportAllocationResponse],
    dependencies=[Depends(require_role("admin"))],
)
def student_transport(
    student_id: int,
    db: Session = Depends(get_db),
):
    allocations = (
        transport_allocation_query(db)
        .filter(StudentTransportAllocationV2.student_id == student_id)
        .order_by(StudentTransportAllocationV2.allocated_at.desc())
        .all()
    )
    assignments = active_assignment_map(db)
    return [allocation_payload(item, assignments) for item in allocations]


@router.patch(
    "/allocations/{allocation_id}/status",
    response_model=StudentTransportAllocationResponse,
    dependencies=[Depends(require_role("admin"))],
)
def update_allocation_status(
    allocation_id: int,
    request: TransportAllocationStatusRequest,
    db: Session = Depends(get_db),
):
    if request.status not in ALLOCATION_STATUSES:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid transport allocation status",
        )

    allocation = (
        db.query(StudentTransportAllocationV2)
        .filter(StudentTransportAllocationV2.id == allocation_id)
        .first()
    )

    if allocation is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Transport allocation not found",
        )

    allocation.status = request.status

    if request.status != "active":
        allocation.deactivated_at = datetime.now(timezone.utc)

    db.commit()
    db.refresh(allocation)

    allocation = transport_allocation_query(db).filter(
        StudentTransportAllocationV2.id == allocation.id
    ).first()
    return allocation_payload(allocation, active_assignment_map(db))


@router.post(
    "/issues",
    response_model=TransportIssueResponse,
)
def create_issue(
    request: TransportIssueCreateRequest,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    student = get_student_by_user(db, current_user.id)

    if request.priority not in ISSUE_PRIORITIES:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid issue priority",
        )

    allocation = (
        db.query(StudentTransportAllocationV2)
        .filter(
            StudentTransportAllocationV2.student_id == student.id,
            StudentTransportAllocationV2.status == "active",
        )
        .first()
    )

    issue = TransportIssueV2(
        student_id=student.id,
        allocation_id=allocation.id if allocation else None,
        issue_number=f"TI-{uuid4().hex[:12].upper()}",
        category=request.category,
        title=request.title,
        description=request.description,
        priority=request.priority,
        status="open",
    )

    db.add(issue)
    db.commit()
    db.refresh(issue)

    issue = issue_query(db).filter(TransportIssueV2.id == issue.id).first()
    return issue_payload(issue)


@router.get(
    "/issues/me",
    response_model=list[TransportIssueResponse],
)
def my_issues(
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    student = get_student_by_user(db, current_user.id)

    issues = (
        issue_query(db)
        .filter(TransportIssueV2.student_id == student.id)
        .order_by(TransportIssueV2.created_at.desc())
        .all()
    )
    return [issue_payload(item) for item in issues]


@router.get(
    "/issues/admin",
    response_model=list[TransportIssueResponse],
    dependencies=[Depends(require_role("admin"))],
)
def admin_issues(
    issue_status: str | None = None,
    db: Session = Depends(get_db),
):
    query = issue_query(db)

    if issue_status:
        query = query.filter(
            TransportIssueV2.status == issue_status
        )

    issues = query.order_by(
        TransportIssueV2.created_at.desc()
    ).all()
    return [issue_payload(item) for item in issues]


@router.patch(
    "/issues/{issue_id}/resolve",
    response_model=TransportIssueResponse,
    dependencies=[Depends(require_role("admin"))],
)
def resolve_issue(
    issue_id: int,
    request: TransportIssueResolveRequest,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    issue = (
        db.query(TransportIssueV2)
        .filter(TransportIssueV2.id == issue_id)
        .first()
    )

    if issue is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Transport issue not found",
        )

    issue.resolution = request.resolution
    issue.status = "resolved"
    issue.resolved_at = datetime.now(timezone.utc)
    issue.resolved_by_user_id = current_user.id

    db.commit()
    db.refresh(issue)

    issue = issue_query(db).filter(TransportIssueV2.id == issue.id).first()
    return issue_payload(issue)
