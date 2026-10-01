from app.core.database import Base
import app.models

def test_models_registered():
    assert len(Base.metadata.tables) >= 50

def test_core_tables_registered():
    tables = Base.metadata.tables
    required = {
        "users",
        "students",
        "universities",
        "courses",
        "attendance",
        "fee_records",
    }
    assert required.issubset(set(tables))


def test_programme_catalog_table_registered():
    assert "programme_specializations" in Base.metadata.tables

def test_security_tables_registered():
    tables = Base.metadata.tables
    required = {
        "permissions",
        "role_permissions",
        "user_permissions",
        "audit_logs",
    }
    assert required.issubset(set(tables))

def test_intelligence_tables_registered():
    tables = Base.metadata.tables
    required = {
        "risk_assessments",
        "early_warnings",
        "academic_interventions",
    }
    assert required.issubset(set(tables))

def test_passport_tables_registered():
    tables = Base.metadata.tables
    required = {
        "academic_passports",
        "passport_share_consents",
    }
    assert required.issubset(set(tables))
