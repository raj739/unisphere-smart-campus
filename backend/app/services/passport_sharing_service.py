import secrets
from datetime import datetime

from sqlalchemy.orm import Session

from app.models.academic_passport import AcademicPassport
from app.models.passport_share_consent import PassportShareConsent


class PassportSharingService:

    @staticmethod
    def generate_token() -> str:
        return secrets.token_urlsafe(48)

    @staticmethod
    def is_valid(consent: PassportShareConsent) -> bool:
        if not consent.is_active:
            return False

        if consent.status != "Active":
            return False

        if consent.expires_at is not None:
            if datetime.utcnow() >= consent.expires_at:
                return False

        return True

    @classmethod
    def expire_if_needed(
        cls,
        db: Session,
        consent: PassportShareConsent,
    ) -> PassportShareConsent:

        if (
            consent.is_active
            and consent.expires_at is not None
            and datetime.utcnow() >= consent.expires_at
        ):
            consent.status = "Expired"
            consent.is_active = False
            db.commit()
            db.refresh(consent)

        return consent

    @classmethod
    def revoke(
        cls,
        db: Session,
        consent: PassportShareConsent,
    ) -> PassportShareConsent:

        consent.status = "Revoked"
        consent.is_active = False
        consent.revoked_at = datetime.utcnow()

        db.commit()
        db.refresh(consent)

        return consent

    @staticmethod
    def scope_list(scope: str) -> list[str]:
        return [
            item.strip()
            for item in scope.split(",")
            if item.strip()
        ]

    @classmethod
    def build_shared_passport(
        cls,
        passport: AcademicPassport,
        consent: PassportShareConsent,
    ) -> dict:

        scopes = cls.scope_list(consent.scope)

        data = {
            "valid": True,
            "status": consent.status,
            "recipient_name": consent.recipient_name,
            "purpose": consent.purpose,
            "scope": scopes,
            "expires_at": consent.expires_at,
        }

        if "identity" in scopes:
            data.update(
                {
                    "passport_number": passport.passport_number,
                    "full_name": passport.full_name,
                    "uni_id": passport.uni_id,
                }
            )

        if "academic" in scopes:
            data.update(
                {
                    "programme": passport.programme,
                    "academic_session": passport.academic_session,
                }
            )

        return data
