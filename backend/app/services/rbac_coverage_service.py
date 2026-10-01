from __future__ import annotations

from pathlib import Path

from app.core.rbac_enforcement import PERMISSION_RULES


class RBACCoverageService:
    """Static source-level RBAC coverage audit."""

    @staticmethod
    def scan_api_directory() -> dict:
        root = Path(__file__).resolve().parents[1] / "api" / "v1"

        sensitive_modules = {
            "students",
            "student",
            "academics",
            "courses",
            "enrollments",
            "attendance",
            "examinations",
            "exam",
            "fees",
            "payments",
            "hostel",
            "transport",
            "helpdesk",
            "grievance",
            "notifications",
            "ai",
            "ai_v2",
            "risk",
            "early_warning",
            "interventions_v2",
            "academic_passport",
            "passport_sharing",
            "audit",
            "analytics",
        }

        results = []

        for path in sorted(root.glob("*.py")):
            stem = path.stem

            if stem not in sensitive_modules:
                continue

            text = path.read_text(
                encoding="utf-8",
                errors="ignore",
            )

            protected = (
                "require_permission" in text
                or "RBACService" in text
                or "require_admin" in text
                or "require_role" in text
            )

            results.append(
                {
                    "module": stem,
                    "file": str(path),
                    "protected": protected,
                }
            )

        total = len(results)
        protected = sum(
            1 for item in results if item["protected"]
        )

        return {
            "total_sensitive_modules": total,
            "protected_modules": protected,
            "unprotected_modules": total - protected,
            "coverage_percent": (
                round((protected / total) * 100, 2)
                if total
                else 100.0
            ),
            "permission_rules": len(PERMISSION_RULES),
            "modules": results,
        }