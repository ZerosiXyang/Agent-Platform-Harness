"""FastAPI 应用入口测试。"""

from fastapi.testclient import TestClient

from backend.main import app


def test_health_returns_ok() -> None:
    """GET /health 应返回 200 且 status=ok。"""
    client = TestClient(app)
    response = client.get("/health")

    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_env_dependent_failure() -> None:
    """场景6：只在 CI backend job 失败（有 DATABASE_URL）、self-heal 环境绿（无）——触发静默 no-op。

    backend gates 有 PG service 注入 DATABASE_URL；self-heal job 没有该 env。
    因此：CI 红，但 codex 跑时 pytest 已绿 → 无 diff → porcelain exit 1。
    """
    import os

    assert "DATABASE_URL" not in os.environ, "CI 环境不应有 DATABASE_URL（场景6 构造）"
