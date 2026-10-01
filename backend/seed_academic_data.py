from app.core.database import SessionLocal
from app.models.course import Course
from app.models.semester import Semester
from app.models.student import Student
from app.models.student_course import StudentCourse
from app.models.attendance import Attendance
from app.models.result import Result
from app.models.timetable import TimetableEntry
from app.models.examination import Examination


db = SessionLocal()

try:
    student = (
        db.query(Student)
        .filter(Student.uni_id == "UNI-MP-VU-BCA-2026-001247")
        .first()
    )

    if student is None:
        print("Aarav student profile not found.")
        raise SystemExit

    # ---------------------------------------------------------
    # Semester
    # ---------------------------------------------------------

    semester = (
        db.query(Semester)
        .filter(
            Semester.number == 4,
            Semester.academic_year == "2026",
        )
        .first()
    )

    if semester is None:
        semester = Semester(
            number=4,
            name="Semester 4",
            academic_year="2026",
        )
        db.add(semester)
        db.flush()
        print("Semester 4 created.")
    else:
        print("Semester 4 already exists.")

    # ---------------------------------------------------------
    # Courses
    # ---------------------------------------------------------

    course_data = [
        ("CS401", "Database Management Systems", 4),
        ("CS402", "Computer Networks", 4),
        ("CS403", "Operating Systems", 4),
        ("CS404", "Software Engineering", 4),
        ("CS405", "Web Technologies", 4),
    ]

    courses = {}

    for code, name, credits in course_data:
        course = (
            db.query(Course)
            .filter(Course.code == code)
            .first()
        )

        if course is None:
            course = Course(
                code=code,
                name=name,
                credits=credits,
            )
            db.add(course)
            db.flush()
            print(f"Course created: {code}")
        else:
            print(f"Course already exists: {code}")

        courses[code] = course

    # ---------------------------------------------------------
    # Student-Course enrollment
    # ---------------------------------------------------------

    for code, course in courses.items():
        enrollment = (
            db.query(StudentCourse)
            .filter(
                StudentCourse.student_id == student.id,
                StudentCourse.course_id == course.id,
                StudentCourse.semester_id == semester.id,
            )
            .first()
        )

        if enrollment is None:
            db.add(
                StudentCourse(
                    student_id=student.id,
                    course_id=course.id,
                    semester_id=semester.id,
                )
            )
            print(f"Enrolled: {code}")

    db.flush()

    # ---------------------------------------------------------
    # Attendance
    # ---------------------------------------------------------

    attendance_data = {
        "CS401": (40, 27, 67.5),
        "CS402": (40, 34, 85.0),
        "CS403": (42, 38, 90.48),
        "CS404": (40, 31, 77.5),
        "CS405": (40, 35, 87.5),
    }

    for code, (held, attended, percentage) in attendance_data.items():
        course = courses[code]

        record = (
            db.query(Attendance)
            .filter(
                Attendance.student_id == student.id,
                Attendance.course_id == course.id,
            )
            .first()
        )

        if record is None:
            db.add(
                Attendance(
                    student_id=student.id,
                    course_id=course.id,
                    classes_held=held,
                    classes_attended=attended,
                    percentage=percentage,
                )
            )
            print(f"Attendance created: {code}")

    # ---------------------------------------------------------
    # Results
    # ---------------------------------------------------------

    result_data = {
        "CS401": ("B+", 8.0, 78),
        "CS402": ("A", 9.0, 84),
        "CS403": ("A+", 10.0, 91),
        "CS404": ("A", 9.0, 79),
        "CS405": ("A+", 10.0, 88),
    }

    for code, (grade, grade_point, marks) in result_data.items():
        course = courses[code]

        record = (
            db.query(Result)
            .filter(
                Result.student_id == student.id,
                Result.course_id == course.id,
                Result.semester_id == semester.id,
            )
            .first()
        )

        if record is None:
            db.add(
                Result(
                    student_id=student.id,
                    course_id=course.id,
                    semester_id=semester.id,
                    grade=grade,
                    grade_point=grade_point,
                    marks=marks,
                )
            )
            print(f"Result created: {code}")

    # ---------------------------------------------------------
    # Timetable
    # ---------------------------------------------------------

    timetable_data = [
        ("CS401", "Monday", "10:00", "11:00", "Dr Rajesh Verma", "Room 204", "Lecture"),
        ("CS402", "Monday", "12:00", "13:00", "Dr Neha Sharma", "Room 105", "Lecture"),
        ("CS403", "Monday", "14:00", "16:00", "Prof Amit Jain", "Lab 2", "Lab"),
        ("CS404", "Tuesday", "09:00", "10:00", "Dr Priya Mehta", "Room 301", "Lecture"),
        ("CS405", "Tuesday", "11:00", "12:00", "Prof Ankit Sharma", "Room 202", "Lecture"),
        ("CS401", "Tuesday", "14:00", "16:00", "Dr Rajesh Verma", "Lab 1", "Lab"),
        ("CS403", "Wednesday", "10:00", "11:00", "Prof Amit Jain", "Room 206", "Lecture"),
        ("CS405", "Wednesday", "12:00", "13:00", "Prof Ankit Sharma", "Room 202", "Lecture"),
        ("CS402", "Thursday", "09:00", "10:00", "Dr Neha Sharma", "Room 105", "Lecture"),
        ("CS404", "Thursday", "11:00", "12:00", "Dr Priya Mehta", "Room 301", "Lecture"),
        ("CS405", "Thursday", "14:00", "16:00", "Prof Ankit Sharma", "Lab 3", "Lab"),
        ("CS401", "Friday", "10:00", "11:00", "Dr Rajesh Verma", "Room 204", "Lecture"),
        ("CS403", "Friday", "12:00", "13:00", "Prof Amit Jain", "Room 206", "Lecture"),
        ("CS402", "Friday", "14:00", "15:00", "Dr Neha Sharma", "Room 105", "Lecture"),
        ("CS404", "Saturday", "09:00", "11:00", "Dr Priya Mehta", "Lab 4", "Workshop"),
        ("CS405", "Saturday", "11:30", "12:30", "Prof Ankit Sharma", "Room 202", "Lecture"),
    ]

    for (
        code,
        day,
        start,
        end,
        faculty,
        room,
        session_type,
    ) in timetable_data:
        course = courses[code]

        existing = (
            db.query(TimetableEntry)
            .filter(
                TimetableEntry.course_id == course.id,
                TimetableEntry.day_of_week == day,
                TimetableEntry.start_time == start,
            )
            .first()
        )

        if existing is None:
            db.add(
                TimetableEntry(
                    course_id=course.id,
                    day_of_week=day,
                    start_time=start,
                    end_time=end,
                    faculty_name=faculty,
                    room=room,
                    session_type=session_type,
                )
            )

    # ---------------------------------------------------------
    # Examinations
    # ---------------------------------------------------------

    examination_data = [
        ("CS401", "Database Management Systems", "2026-10-12", "10:00", "13:00", "Hall A"),
        ("CS402", "Computer Networks", "2026-10-15", "10:00", "13:00", "Hall B"),
        ("CS403", "Operating Systems", "2026-10-18", "10:00", "13:00", "Hall A"),
        ("CS404", "Software Engineering", "2026-10-21", "10:00", "13:00", "Hall C"),
        ("CS405", "Web Technologies", "2026-10-24", "10:00", "13:00", "Hall B"),
    ]

    for (
        code,
        exam_name,
        exam_date,
        start,
        end,
        venue,
    ) in examination_data:
        course = courses[code]

        existing = (
            db.query(Examination)
            .filter(
                Examination.course_id == course.id,
                Examination.semester_id == semester.id,
            )
            .first()
        )

        if existing is None:
            db.add(
                Examination(
                    course_id=course.id,
                    semester_id=semester.id,
                    examination_name=exam_name,
                    exam_date=exam_date,
                    start_time=start,
                    end_time=end,
                    venue=venue,
                )
            )

    db.commit()

    print("")
    print("Academic demo data seeded successfully.")
    print("Courses: 5")
    print("Attendance records: 5")
    print("Result records: 5")
    print("Timetable entries: 16")
    print("Examinations: 5")

finally:
    db.close()
