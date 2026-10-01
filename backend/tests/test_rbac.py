from app.core.rbac_enforcement import (
    PERMISSION_RULES,
    is_public_path,
    rule_for_path,
)

def test_permission_registry_exists():
    assert len(PERMISSION_RULES) >= 20

def test_public_paths():
    assert is_public_path("/docs")
    assert is_public_path("/openapi.json")
    assert is_public_path("/api/v1/auth/login")

def test_sensitive_paths_are_not_public():
    assert not is_public_path("/api/v1/students")
    assert not is_public_path("/api/v1/fees")
    assert not is_public_path("/api/v1/analytics")

def test_student_permission_rule():
    rule = rule_for_path("/api/v1/students", "GET")
    assert rule is not None
    assert rule.permission == "students.read"

def test_fee_permission_rule():
    rule = rule_for_path("/api/v1/fees", "GET")
    assert rule is not None
    assert rule.permission == "fees.read"

def test_analytics_permission_rule():
    rule = rule_for_path("/api/v1/analytics/overview", "GET")
    assert rule is not None
    assert rule.permission == "reports.read"

def test_ai_permission_rule():
    rule = rule_for_path("/api/v1/ai-v2/chat", "POST")
    assert rule is not None
    assert rule.permission == "ai.use"