from sqlalchemy import Column, ForeignKey, Integer, String

from app.core.database import Base


class HostelAllocation(Base):
    __tablename__ = "hostel_allocations"

    id = Column(Integer, primary_key=True, index=True)

    student_id = Column(
        Integer,
        ForeignKey("students.id"),
        nullable=False,
    )

    hostel_name = Column(String(200), nullable=False)
    block = Column(String(50), nullable=True)
    room_number = Column(String(50), nullable=False)
    bed_number = Column(String(50), nullable=True)
    sharing_type = Column(String(100), nullable=True)

    academic_year = Column(String(50), nullable=False)
    fee_amount = Column(Integer, nullable=False, default=0)

    warden_name = Column(String(150), nullable=True)
    status = Column(String(50), nullable=False, default="Allocated")
