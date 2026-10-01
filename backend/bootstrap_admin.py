"""Create the first administrator in an empty local database."""

from getpass import getpass

from dotenv import load_dotenv

load_dotenv()

from app.core.database import SessionLocal  # noqa: E402
from app.core.security import hash_password  # noqa: E402
from app.models.user import User  # noqa: E402


def main() -> None:
    email = input("Admin email: ").strip().lower()
    if not email or "@" not in email:
        raise SystemExit("Enter a valid email address.")

    password = getpass("Admin password (at least 12 characters): ")
    if len(password) < 12:
        raise SystemExit("Admin password must contain at least 12 characters.")
    if password != getpass("Confirm password: "):
        raise SystemExit("Passwords do not match.")

    with SessionLocal() as db:
        if db.query(User).filter(User.email == email).first():
            raise SystemExit("An account with this email already exists.")
        db.add(User(email=email, password_hash=hash_password(password), role="admin", is_active=True))
        db.commit()
    print("Admin account created.")


if __name__ == "__main__":
    main()
