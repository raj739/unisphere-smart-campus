from app.core.database import SessionLocal
from app.models.user import User
from app.models.student import Student
from app.models.department import Department

db = SessionLocal()

try:
    user = (
        db.query(User)
        .filter(User.email == "aarav@unisphere.edu")
        .first()
    )

    if user is None:
        print("User not found.")
    else:
        department = (
            db.query(Department)
            .filter(Department.code == "BCA")
            .first()
        )

        if department is None:
            print("BCA department not found.")
        else:
            existing_student = (
                db.query(Student)
                .filter(Student.user_id == user.id)
                .first()
            )

            if existing_student:
                print("Aarav student profile already exists.")
                print(f"Student ID: {existing_student.id}")
                print(f"Uni-ID: {existing_student.uni_id}")
            else:
                student = Student(
                    user_id=user.id,
                    department_id=department.id,
                    uni_id="UNI-MP-VU-BCA-2026-001247",
                    university_id="VU-BCA-24-1247",
                    enrollment_number="VU2024BCA1247",
                    full_name="Aarav Sharma",
                    programme="BCA",
                    current_semester=4,
                    academic_session="2024-2027",
                )

                db.add(student)
                db.commit()
                db.refresh(student)

                print("Aarav student profile created.")
                print(f"Student ID: {student.id}")
                print(f"Uni-ID: {student.uni_id}")
                print(f"Department ID: {student.department_id}")

finally:
    db.close()
