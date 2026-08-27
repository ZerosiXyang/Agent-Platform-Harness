# 依赖修复记录

> 记录 2026-08 清理迭代中发现的「需求文档依赖 vs PyPI 现实」冲突及其修复。
> 证据链保留，供后续升级依赖时对照。

## 修复 1：`langgraph-store-postgres` 包不存在

- **现象**：`pip install -e ".[dev]"` 报 `No matching distribution found for langgraph-store-postgres>=1.0.0`
- **查证**：`pip index versions langgraph-store-postgres` → 无任何版本（PyPI 上不存在此包）
- **真相**：解包 `langgraph-checkpoint-postgres` 3.1.2 的 wheel，确认 `langgraph/store/postgres/base.py`
  内含 `class PostgresStore`。即**短期记忆 Saver 与长期记忆 Store 由同一个包提供**。
- **根因**：需求文档 §7 写的是模块路径 `langgraph.store.postgres`，被误译成 PyPI 包名 `langgraph-store-postgres`。
- **修复**：从 `backend/pyproject.toml` 删除 `langgraph-store-postgres>=1.0.0` 依赖。
  未来如需导入长期记忆，直接 `from langgraph.store.postgres import PostgresStore` 即可。

## 修复 2：`[dependency-groups]` 与 `.[dev]` 不匹配

- **现象**：`pip install -e ".[dev]"` 成功，但 pytest / ruff 并未安装。
- **根因**：dev 依赖声明用了 PEP 735 的 `[dependency-groups]`，而 CI 与 `run_tests.sh`
  用的是 extras 语法 `.[dev]`（对应 `[project.optional-dependencies]`），两者不兼容，
  pip 把 `[dev]` 当作不存在的 extra 静默忽略。
- **修复**：将 `[dependency-groups]` 改为 `[project.optional-dependencies]`，使 `.[dev]` 生效。

## 修复 3：补充最小测试

- **现象**：`pytest --cov=langgraph --cov=db` 在无测试文件时以退出码 5（no tests ran）失败，
  导致 `run_tests.sh` 假失败。
- **修复**：新增 `backend/__init__.py`、`backend/tests/__init__.py`、`backend/tests/test_health.py`，
  以及 dev 依赖 `httpx>=0.27.0`（TestClient 需要）。

## 修复 4：editable 安装结构错配（pyproject 位置）

- **现象**：`pip install -e` 后，`import backend` 仅在 cwd 恰好为项目根时可用，从其他目录（如 `/tmp`）报 `ModuleNotFoundError`。
- **查证**：site-packages 中无 backend 的 import 钩子；`direct_url.json` 的 url 指向 `.../backend`。
- **根因**：`pyproject.toml` 位于 `backend/` 内，却声明 `packages = ["backend"]`（期望 backend 是项目根下的子包）。
  hatchling 在 `backend/` 内找不到 `backend/` 子包，editable 模式因此不生成 import 钩子。
- **修复**：将 `pyproject.toml` 上移到项目根，`backend/` 成为标准 flat-layout 子包；同步调整
  `run_tests.sh` 与 CI（从项目根运行 `ruff check backend`、`pytest`），`--cov` 改为 `--cov=backend`、
  新增 `testpaths = ["backend/tests"]`。修复后从任意目录 `import backend` 均成功。

## 结论

当前实际安装版本（均满足需求文档 §7 下限）：

| 依赖 | 需求下限 | 实际版本 |
|------|----------|----------|
| langgraph | 0.2.50 | 1.2.11 |
| langchain | 0.3.0 | 1.3.17 |
| langgraph-checkpoint-postgres | 2.0.0 | 3.1.2 |
| pymilvus | 2.4.0 | 3.0.1 |
| fastapi | 0.115.0 | 0.141.1 |
| langsmith | 0.1.0 | 0.11.1 |

> 注意：pymilvus 客户端 3.x 与 Milvus 服务端版本对应关系需在部署阶段确认（客户端 3.x 通常对应服务端 2.5+）。
