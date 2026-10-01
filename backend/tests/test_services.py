def test_rbac_service_import():
    from app.services.rbac_service import RBACService
    assert RBACService is not None

def test_risk_engine_import():
    from app.services.risk_engine import RiskEngine
    assert RiskEngine is not None

def test_early_warning_engine_import():
    from app.services.early_warning_engine import EarlyWarningEngine
    assert EarlyWarningEngine is not None

def test_audit_service_import():
    from app.services.audit_service import AuditService
    assert AuditService is not None

def test_analytics_service_import():
    from app.services.analytics_service import AnalyticsService
    assert AnalyticsService is not None

def test_event_service_import():
    from app.services.event_service import EventService
    assert EventService is not None

def test_realtime_manager_import():
    from app.services.realtime_manager import RealtimeManager
    assert RealtimeManager is not None