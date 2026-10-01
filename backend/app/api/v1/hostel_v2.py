from datetime import datetime, timezone
from uuid import uuid4

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session, joinedload, selectinload

from app.core.database import get_db
from app.core.dependencies import get_current_user, require_role
from app.models.hostel_building_v2 import HostelBuildingV2
from app.models.hostel_room_v2 import HostelRoomV2
from app.models.hostel_allocation_v2 import HostelAllocationV2
from app.models.hostel_complaint_v2 import HostelComplaintV2
from app.models.student import Student
from app.schemas.hostel_v2 import (
    HostelBuildingCreateRequest,
    HostelBuildingResponse,
    HostelRoomCreateRequest,
    HostelRoomResponse,
    HostelAllocationCreateRequest,
    HostelAllocationResponse,
    HostelAllocationStatusRequest,
    HostelComplaintCreateRequest,
    HostelComplaintResponse,
    HostelComplaintResolveRequest,
)

router = APIRouter(prefix="/hostel-v2", tags=["Hostel V2"])

ALLOCATION_STATUSES = {
    "allocated",
    "checked_in",
    "checked_out",
    "cancelled",
}

COMPLAINT_PRIORITIES = {
    "low",
    "normal",
    "high",
    "urgent",
}

COMPLAINT_STATUSES = {
    "open",
    "in_progress",
    "resolved",
    "closed",
}


def get_student_by_user(db: Session, user_id: int):
    student = db.query(Student).filter(Student.user_id == user_id).first()

    if student is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Student profile not found",
        )

    return student


def refresh_room_status(room: HostelRoomV2):
    if not room.is_active:
        room.status = "inactive"
    elif room.occupied_count >= room.capacity:
        room.status = "full"
    elif room.occupied_count > 0:
        room.status = "partially_occupied"
    else:
        room.status = "available"


def allocation_payload(allocation: HostelAllocationV2):
    student = allocation.student
    room = allocation.room
    building = room.building if room else None
    return {
        "id": allocation.id,
        "student_id": allocation.student_id,
        "room_id": allocation.room_id,
        "allocation_number": allocation.allocation_number,
        "status": allocation.status,
        "allocated_at": allocation.allocated_at,
        "check_in_at": allocation.check_in_at,
        "check_out_at": allocation.check_out_at,
        "remarks": allocation.remarks,
        "student_name": student.full_name if student else None,
        "student_uni_id": (
            student.university_id or student.uni_id if student else None
        ),
        "student_programme": student.programme if student else None,
        "building_id": building.id if building else None,
        "building_name": building.name if building else None,
        "building_code": building.code if building else None,
        "hostel_type": building.hostel_type if building else None,
        "room_number": room.room_number if room else None,
        "floor_number": room.floor_number if room else None,
        "room_type": room.room_type if room else None,
        "room_capacity": room.capacity if room else None,
        "room_occupied_count": room.occupied_count if room else None,
        "room_status": room.status if room else None,
    }


def complaint_payload(complaint: HostelComplaintV2):
    student = complaint.student
    room = complaint.room
    building = room.building if room else None
    return {
        "id": complaint.id,
        "student_id": complaint.student_id,
        "room_id": complaint.room_id,
        "complaint_number": complaint.complaint_number,
        "category": complaint.category,
        "title": complaint.title,
        "description": complaint.description,
        "priority": complaint.priority,
        "status": complaint.status,
        "resolution": complaint.resolution,
        "created_at": complaint.created_at,
        "resolved_at": complaint.resolved_at,
        "student_name": student.full_name if student else None,
        "student_uni_id": (
            student.university_id or student.uni_id if student else None
        ),
        "building_name": building.name if building else None,
        "room_number": room.room_number if room else None,
    }


def allocation_query(db: Session):
    return db.query(HostelAllocationV2).options(
        joinedload(HostelAllocationV2.student),
        joinedload(HostelAllocationV2.room).joinedload(HostelRoomV2.building),
    )


def complaint_query(db: Session):
    return db.query(HostelComplaintV2).options(
        joinedload(HostelComplaintV2.student),
        joinedload(HostelComplaintV2.room).joinedload(HostelRoomV2.building),
    )


@router.post(
    "/buildings",
    response_model=HostelBuildingResponse,
    dependencies=[Depends(require_role("admin"))],
)
def create_building(
    request: HostelBuildingCreateRequest,
    db: Session = Depends(get_db),
):
    existing = (
        db.query(HostelBuildingV2)
        .filter(HostelBuildingV2.code == request.code)
        .first()
    )

    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Hostel building code already exists",
        )

    building = HostelBuildingV2(**request.model_dump())
    db.add(building)
    db.commit()
    db.refresh(building)

    return building


@router.get(
    "/buildings",
    response_model=list[HostelBuildingResponse],
)
def list_buildings(
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return (
        db.query(HostelBuildingV2)
        .filter(HostelBuildingV2.is_active == True)
        .order_by(HostelBuildingV2.name)
        .all()
    )


@router.post(
    "/rooms",
    response_model=HostelRoomResponse,
    dependencies=[Depends(require_role("admin"))],
)
def create_room(
    request: HostelRoomCreateRequest,
    db: Session = Depends(get_db),
):
    building = (
        db.query(HostelBuildingV2)
        .filter(HostelBuildingV2.id == request.building_id)
        .first()
    )

    if building is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Hostel building not found",
        )

    existing = (
        db.query(HostelRoomV2)
        .filter(
            HostelRoomV2.building_id == request.building_id,
            HostelRoomV2.room_number == request.room_number,
        )
        .first()
    )

    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Room number already exists in this building",
        )

    room = HostelRoomV2(**request.model_dump())
    refresh_room_status(room)

    db.add(room)
    db.commit()
    db.refresh(room)

    return room


@router.get(
    "/rooms",
    response_model=list[HostelRoomResponse],
)
def list_rooms(
    building_id: int | None = None,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    query = db.query(HostelRoomV2).filter(
        HostelRoomV2.is_active == True
    )

    if building_id is not None:
        query = query.filter(
            HostelRoomV2.building_id == building_id
        )

    return query.order_by(
        HostelRoomV2.building_id,
        HostelRoomV2.room_number,
    ).all()


@router.post(
    "/allocations",
    response_model=HostelAllocationResponse,
    dependencies=[Depends(require_role("admin"))],
)
def create_allocation(
    request: HostelAllocationCreateRequest,
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

    room = (
        db.query(HostelRoomV2)
        .filter(HostelRoomV2.id == request.room_id)
        .first()
    )

    if room is None or not room.is_active:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Active hostel room not found",
        )

    active_allocation = (
        db.query(HostelAllocationV2)
        .filter(
            HostelAllocationV2.student_id == request.student_id,
            HostelAllocationV2.status.in_(
                ["allocated", "checked_in"]
            ),
        )
        .first()
    )

    if active_allocation:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Student already has an active hostel allocation",
        )

    if room.occupied_count >= room.capacity:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Hostel room is full",
        )

    allocation = HostelAllocationV2(
        student_id=request.student_id,
        room_id=request.room_id,
        allocation_number=f"HA-{uuid4().hex[:12].upper()}",
        status="allocated",
        remarks=request.remarks,
        allocated_by_user_id=current_user.id,
    )

    room.occupied_count += 1
    refresh_room_status(room)

    db.add(allocation)
    db.commit()
    db.refresh(allocation)

    allocation = allocation_query(db).filter(
        HostelAllocationV2.id == allocation.id
    ).first()
    return allocation_payload(allocation)


@router.get(
    "/allocations",
    response_model=list[HostelAllocationResponse],
    dependencies=[Depends(require_role("admin"))],
)
def list_allocations(
    db: Session = Depends(get_db),
):
    allocations = (
        allocation_query(db)
        .order_by(HostelAllocationV2.allocated_at.desc())
        .all()
    )
    return [allocation_payload(item) for item in allocations]


@router.get(
    "/me",
    response_model=list[HostelAllocationResponse],
)
def my_allocations(
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    student = get_student_by_user(db, current_user.id)

    allocations = (
        allocation_query(db)
        .filter(HostelAllocationV2.student_id == student.id)
        .order_by(HostelAllocationV2.allocated_at.desc())
        .all()
    )
    return [allocation_payload(item) for item in allocations]


@router.get(
    "/admin/overview",
    dependencies=[Depends(require_role("admin"))],
)
def admin_overview(db: Session = Depends(get_db)):
    buildings = (
        db.query(HostelBuildingV2)
        .options(selectinload(HostelBuildingV2.rooms))
        .filter(HostelBuildingV2.is_active == True)
        .order_by(HostelBuildingV2.name)
        .all()
    )
    allocations = allocation_query(db).order_by(
        HostelAllocationV2.allocated_at.desc()
    ).all()
    complaints = complaint_query(db).order_by(
        HostelComplaintV2.created_at.desc()
    ).all()

    active_allocations = [
        item for item in allocations
        if item.status in {"allocated", "checked_in"}
    ]
    occupants_by_room = {}
    for item in active_allocations:
        occupants_by_room.setdefault(item.room_id, []).append({
            "student_id": item.student_id,
            "student_name": item.student.full_name,
            "student_uni_id": item.student.university_id or item.student.uni_id,
            "allocation_number": item.allocation_number,
            "status": item.status,
        })

    room_rows = []
    building_rows = []
    for building in buildings:
        active_rooms = [room for room in building.rooms if room.is_active]
        capacity = sum(room.capacity for room in active_rooms)
        occupied = sum(room.occupied_count for room in active_rooms)
        building_rows.append({
            "id": building.id,
            "name": building.name,
            "code": building.code,
            "hostel_type": building.hostel_type,
            "gender": building.gender,
            "address": building.address,
            "total_floors": building.total_floors,
            "room_count": len(active_rooms),
            "capacity": capacity,
            "occupied": occupied,
            "available": max(0, capacity - occupied),
        })
        for room in sorted(active_rooms, key=lambda item: item.room_number):
            room_rows.append({
                "id": room.id,
                "building_id": building.id,
                "building_name": building.name,
                "building_code": building.code,
                "room_number": room.room_number,
                "floor_number": room.floor_number,
                "room_type": room.room_type,
                "capacity": room.capacity,
                "occupied_count": room.occupied_count,
                "available_beds": max(0, room.capacity - room.occupied_count),
                "status": room.status,
                "is_active": room.is_active,
                "occupants": occupants_by_room.get(room.id, []),
            })

    total_capacity = sum(item["capacity"] for item in building_rows)
    occupied_beds = sum(item["occupied"] for item in building_rows)
    return {
        "metrics": {
            "building_count": len(building_rows),
            "room_count": len(room_rows),
            "bed_capacity": total_capacity,
            "occupied_beds": occupied_beds,
            "available_beds": max(0, total_capacity - occupied_beds),
            "active_allocations": len(active_allocations),
            "open_complaints": len([
                item for item in complaints
                if item.status in {"open", "in_progress"}
            ]),
        },
        "buildings": building_rows,
        "rooms": room_rows,
        "allocations": [allocation_payload(item) for item in allocations],
        "complaints": [complaint_payload(item) for item in complaints],
    }


@router.get(
    "/students/{student_id}",
    response_model=list[HostelAllocationResponse],
    dependencies=[Depends(require_role("admin"))],
)
def student_allocations(
    student_id: int,
    db: Session = Depends(get_db),
):
    allocations = (
        allocation_query(db)
        .filter(HostelAllocationV2.student_id == student_id)
        .order_by(HostelAllocationV2.allocated_at.desc())
        .all()
    )
    return [allocation_payload(item) for item in allocations]


@router.patch(
    "/allocations/{allocation_id}/status",
    response_model=HostelAllocationResponse,
    dependencies=[Depends(require_role("admin"))],
)
def update_allocation_status(
    allocation_id: int,
    request: HostelAllocationStatusRequest,
    db: Session = Depends(get_db),
):
    if request.status not in ALLOCATION_STATUSES:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid allocation status",
        )

    allocation = (
        db.query(HostelAllocationV2)
        .filter(HostelAllocationV2.id == allocation_id)
        .first()
    )

    if allocation is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Hostel allocation not found",
        )

    old_status = allocation.status
    new_status = request.status

    if old_status == new_status:
        allocation = allocation_query(db).filter(
            HostelAllocationV2.id == allocation.id
        ).first()
        return allocation_payload(allocation)

    room = (
        db.query(HostelRoomV2)
        .filter(HostelRoomV2.id == allocation.room_id)
        .first()
    )

    if room is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Hostel room not found",
        )

    active_old = old_status in {"allocated", "checked_in"}
    active_new = new_status in {"allocated", "checked_in"}

    if active_old and not active_new:
        room.occupied_count = max(0, room.occupied_count - 1)

    elif not active_old and active_new:
        if room.occupied_count >= room.capacity:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Hostel room is full",
            )

        room.occupied_count += 1

    if new_status == "checked_in" and allocation.check_in_at is None:
        allocation.check_in_at = datetime.now(timezone.utc)

    if new_status == "checked_out":
        allocation.check_out_at = datetime.now(timezone.utc)

    allocation.status = new_status
    refresh_room_status(room)

    db.commit()
    db.refresh(allocation)

    allocation = allocation_query(db).filter(
        HostelAllocationV2.id == allocation.id
    ).first()
    return allocation_payload(allocation)


@router.post(
    "/complaints",
    response_model=HostelComplaintResponse,
)
def create_complaint(
    request: HostelComplaintCreateRequest,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    student = get_student_by_user(db, current_user.id)

    if request.priority not in COMPLAINT_PRIORITIES:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid complaint priority",
        )

    allocation = (
        db.query(HostelAllocationV2)
        .filter(
            HostelAllocationV2.student_id == student.id,
            HostelAllocationV2.status.in_(
                ["allocated", "checked_in"]
            ),
        )
        .first()
    )

    room_id = allocation.room_id if allocation else None

    complaint = HostelComplaintV2(
        student_id=student.id,
        room_id=room_id,
        complaint_number=f"HC-{uuid4().hex[:12].upper()}",
        category=request.category,
        title=request.title,
        description=request.description,
        priority=request.priority,
        status="open",
    )

    db.add(complaint)
    db.commit()
    db.refresh(complaint)

    complaint = complaint_query(db).filter(
        HostelComplaintV2.id == complaint.id
    ).first()
    return complaint_payload(complaint)


@router.get(
    "/complaints/me",
    response_model=list[HostelComplaintResponse],
)
def my_complaints(
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    student = get_student_by_user(db, current_user.id)

    complaints = (
        complaint_query(db)
        .filter(HostelComplaintV2.student_id == student.id)
        .order_by(HostelComplaintV2.created_at.desc())
        .all()
    )
    return [complaint_payload(item) for item in complaints]


@router.get(
    "/complaints/admin",
    response_model=list[HostelComplaintResponse],
    dependencies=[Depends(require_role("admin"))],
)
def admin_complaints(
    complaint_status: str | None = None,
    db: Session = Depends(get_db),
):
    query = complaint_query(db)

    if complaint_status:
        if complaint_status not in COMPLAINT_STATUSES:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid complaint status",
            )

        query = query.filter(
            HostelComplaintV2.status == complaint_status
        )

    complaints = query.order_by(
        HostelComplaintV2.created_at.desc()
    ).all()
    return [complaint_payload(item) for item in complaints]


@router.patch(
    "/complaints/{complaint_id}/resolve",
    response_model=HostelComplaintResponse,
    dependencies=[Depends(require_role("admin"))],
)
def resolve_complaint(
    complaint_id: int,
    request: HostelComplaintResolveRequest,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    complaint = (
        db.query(HostelComplaintV2)
        .filter(HostelComplaintV2.id == complaint_id)
        .first()
    )

    if complaint is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Hostel complaint not found",
        )

    complaint.resolution = request.resolution
    complaint.status = "resolved"
    complaint.resolved_at = datetime.now(timezone.utc)
    complaint.resolved_by_user_id = current_user.id

    db.commit()
    db.refresh(complaint)

    complaint = complaint_query(db).filter(
        HostelComplaintV2.id == complaint.id
    ).first()
    return complaint_payload(complaint)
