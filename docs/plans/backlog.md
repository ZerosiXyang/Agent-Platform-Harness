# 待办

## Phase 2

- [x] 升级前端 ESLint 10 Flat Config
- [x] 升级后端 Ruff，强制类型提示
- [x] `.github/workflows/agent-ci.yml`（含 failure() 自愈 + LangSmith 打点拦截）
- [x] 本地跑通 `bash run_tests.sh`（venv + 清华镜像；依赖修复见 `dependency-fix.md`）

## Phase 3

- [ ] 拉取 `codex-harness` 沙箱隔离
- [ ] 接入 Superpowers v6.0.3 强制 TDD
- [ ] `prompt_injection_defense.py` 回归测试（REACT-05/06）
- [ ] 三层记忆（thread-level / user-level / cross-session）并行自动化测试
- [ ] SSE 流式交互 Mock 验证（8 种事件类型 + Vue 3 Props 规范）

## 需求文档对齐补充

- [x] 按 §7 版本矩阵锁定 `pyproject.toml` / `package.json` 依赖版本
- [ ] 部署架构（Nginx/CDN + FastAPI + PostgreSQL + Milvus）落地
