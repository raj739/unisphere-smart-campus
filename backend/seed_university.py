from app.core.database import SessionLocal
from app.models.university import University
from app.models.department import Department

db = SessionLocal()

try:
    university = (
        db.query(University)
        .filter(University.code == "VU")
        .first()
    )

    if university is None:
        university = University(
            name="Vikram University",
            code="VU",
            city="Ujjain",
            state="Madhya Pradesh",
        )
        db.add(university)
        db.flush()
        print("University created.")
    else:
        print("University already exists.")

    department = (
        db.query(Department)
        .filter(
            Department.code == "BCA",
            Department.university_id == university.id,
        )
        .first()
    )

    if department is None:
        department = Department(
            name="Computer Applications",
            code="BCA",
            university_id=university.id,
        )
        db.add(department)
        db.flush()
        print("BCA department created.")
    else:
        print("BCA department already exists.")

    db.commit()

    print(f"University ID: {university.id}")
    print(f"Department ID: {department.id}")

finally:
    db.close()
