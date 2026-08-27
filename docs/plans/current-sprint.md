# 当前迭代

## Phase 1：信息层（已完成）

- [x] 根目录 `AGENTS.md`（极简，仅导航到 `docs/`）+ `CLAUDE.md` 桥接
- [x] `docs/` 分层文档结构（已对齐需求文档 v1.0）
- [x] 架构锁死验证（待代码入库后实测：Codex 读取 AGENTS.md 定位 Graph 目录 + 校验 Token 下降）

> 说明：模块级嵌套 `AGENTS.md`（langgraph / db / rag）不预先创建，
> 待对应 `backend/` 子模块真实代码入库后再建立，避免空骨架与双重信息来源。

## Phase 2：约束层（进行中）

- [x] 最小可运行骨架（`backend/` + `frontend/` + `run_tests.sh`）
- [x] 后端 Ruff 配置（强制类型提示 `ANN`、禁未使用导入 `F401`）
- [x] 前端 ESLint 10 Flat Config（锁死组合式 API 规范）
- [x] `.github/workflows/agent-ci.yml`（后端测试 + 前端 lint + LangSmith 打点拦截 + 双核自愈）
- [x] 本地验证：`ruff check` / `pytest` / `npm run lint` 实测通过
- [x] Codex 自愈闭环实测（制造 bug → ruff 捕获 → codex 定位 → codex 修复 → ruff 复检通过）
- [ ] CI 自愈闭环实测（需真实 GitHub Actions 环境）
- [x] 代码审查机制落地（`docs/conventions/code-review.md` + 两阶段 subagent 审查试点通过，审出并修复 langsmith-check grep 误判）

> 说明：`langsmith-check` 依赖真实追踪后端；`self-heal` 已用真实 codex 语法验证，
> 详见 `docs/plans/self-heal-verification.md`。

## Phase 3：自动化层（待开始，依赖基础设施）

- Codex Harness 沙箱 + Superpowers TDD
- ReAct / 三层记忆 / SSE 自动化测试
