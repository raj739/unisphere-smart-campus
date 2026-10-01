"""
UniSphere centralized RBAC enforcement registry.
"""

from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True)
class PermissionRule:
    prefix: str
    permission: str
    methods: tuple[str, ...] = (
        "GET",
        "POST",
        "PUT",
        "PATCH",
        "DELETE",
    )


PERMISSION_RULES: tuple[PermissionRule, ...] = (
    PermissionRule("/api/v1/students", "students.read"),
    PermissionRule("/api/v1/student", "students.read"),
    PermissionRule("/api/v1/academics", "academics.read"),
    PermissionRule("/api/v1/courses", "academics.read"),
    PermissionRule("/api/v1/enrollments", "academics.read"),
    PermissionRule("/api/v1/attendance", "attendance.read"),
    PermissionRule("/api/v1/examinations", "examinations.read"),
    PermissionRule("/api/v1/exam", "examinations.read"),
    PermissionRule("/api/v1/fees", "fees.read"),
    PermissionRule("/api/v1/payments", "fees.read"),
    PermissionRule("/api/v1/hostel", "hostel.read"),
    PermissionRule("/api/v1/transport", "transport.read"),
    PermissionRule("/api/v1/helpdesk", "helpdesk.read"),
    PermissionRule("/api/v1/grievance", "helpdesk.read"),
    PermissionRule("/api/v1/notifications", "notifications.read"),
    PermissionRule("/api/v1/ai-v2", "ai.use"),
    PermissionRule("/api/v1/ai", "ai.use"),
    PermissionRule("/api/v1/risk", "risk.read"),
    PermissionRule("/api/v1/early-warning", "risk.read"),
    PermissionRule("/api/v1/interventions-v2", "interventions.read"),
    PermissionRule("/api/v1/academic-passport", "passport.read"),
    PermissionRule("/api/v1/passport", "passport.read"),
    PermissionRule("/api/v1/audit", "audit.read"),
    PermissionRule("/api/v1/analytics", "reports.read"),
)


PUBLIC_PREFIXES: tuple[str, ...] = (
    "/docs",
    "/redoc",
    "/openapi.json",
    "/api/v1/auth",
    "/api/v1/health",
    "/api/v1/certificates/verify",
    "/api/v1/documents/verify",
    "/api/v1/academic-passport/verify",
    "/api/v1/passport/verify",
)


def is_public_path(path: str) -> bool:
    return any(
        path == prefix or path.startswith(prefix + "/")
        for prefix in PUBLIC_PREFIXES
    )


def rule_for_path(path: str, method: str) -> PermissionRule | None:
    method = method.upper()

    matching = [
        rule
        for rule in PERMISSION_RULES
        if (
            path == rule.prefix
            or path.startswith(rule.prefix + "/")
        )
        and method in rule.methods
    ]

    if not matching:
        return None

    matching.sort(
        key=lambda item: len(item.prefix),
        reverse=True,
    )

    return matching[0]