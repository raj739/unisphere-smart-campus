from app.core.database import SessionLocal
from app.core.security import hash_password
from app.models.user import User
import os


db = SessionLocal()

email = "aarav@unisphere.edu"
password = os.getenv("UNISPHERE_DEMO_PASSWORD", "")
if len(password) < 12:
    raise SystemExit("Set UNISPHERE_DEMO_PASSWORD to a unique password of at least 12 characters.")
role = "student"


existing_user = (
    db.query(User)
    .filter(User.email == email)
    .first()
)


if existing_user:
    print("Demo user already exists.")
    print(f"User ID: {existing_user.id}")
    print(f"Email: {existing_user.email}")
    print(f"Role: {existing_user.role}")
else:
    user = User(
        email=email,
        password_hash=hash_password(password),
        role=role,
        is_active=True,
    )

    db.add(user)
    db.commit()
    db.refresh(user)

    print("Demo user created.")
    print(f"User ID: {user.id}")
    print(f"Email: {email}")
    print(f"Role: {role}")


db.close()
