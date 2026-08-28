"""FastAPI 应用入口测试。"""

from fastapi.testclient import TestClient

from backend.main import app


def test_health_returns_ok() -> None:
    """GET /health 应返回 200 且 status=ok。"""
    client = TestClient(app)
    response = client.get("/health")

    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_semantic_failure() -> None:
    """场景2：故意挂掉的测试，验证 self-heal 语义修复（ruff 修不掉）。"""
    assert 1 == 2, "场景2 语义失败"
