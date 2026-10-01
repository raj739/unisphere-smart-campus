from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_application_imports():
    assert app is not None
    assert app.title

def test_openapi_available():
    response = client.get("/openapi.json")
    assert response.status_code == 200
    data = response.json()
    assert "openapi" in data
    assert "paths" in data

def test_docs_available():
    response = client.get("/docs")
    assert response.status_code == 200