from sqlalchemy import Column, ForeignKey, Integer, String

from app.core.database import Base


class TransportAllocation(Base):
    __tablename__ = "transport_allocations"

    id = Column(Integer, primary_key=True, index=True)

    student_id = Column(
        Integer,
        ForeignKey("students.id"),
        nullable=False,
    )

    route_number = Column(String(50), nullable=False)
    bus_number = Column(String(50), nullable=False)

    pass_status = Column(
        String(50),
        nullable=False,
        default="Active",
    )

    driver_name = Column(String(150), nullable=True)

    departure_time = Column(String(20), nullable=True)
    university_arrival = Column(String(20), nullable=True)

    status = Column(
        String(50),
        nullable=False,
        default="Active",
    )
