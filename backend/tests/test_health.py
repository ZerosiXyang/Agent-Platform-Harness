"""FastAPI 应用入口测试。"""

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# 场景6：导入一个不存在的模块（codex 修不动——不存在可修复的代码路径）
import nonexistent_module_for_scenario6  # noqa: F401

from fastapi.testclient import TestClient

from backend.main import app


def test_health_returns_ok() -> None:
    """GET /health 应返回 200 且 status=ok。"""
    client = TestClient(app)
    response = client.get("/health")

    assert response.status_code == 200
    assert response.json() == {"status": "ok"}
