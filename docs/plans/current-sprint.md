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
- [x] CI 自愈闭环实测（2026-08-27 真实 GH Actions：制造 `import os` → backend 失败 → self-heal（danger-full-access 修复 bwrap 空转）→ codex 删 import → ruff 复检 → auto-heal 分支 → PR #2 自动创建）
- [x] 代码审查机制落地（`docs/conventions/code-review.md` + 两阶段 subagent 审查试点通过，审出并修复 langsmith-check grep 误判）

> 说明：`langsmith-check` 依赖真实追踪后端；`self-heal` 已用真实 codex 语法验证，
> 详见 `docs/plans/self-heal-verification.md`。

## Phase 3：自动化层（开始：三层记忆第一块）

> **起点判定（2026-08-27）**：业务代码（`backend/langgraph|db|rag`）全是空壳，Phase 3 的"自动化测试"依赖它们——所以第一步不是写测试，而是**用 TDD 先实现第一块业务代码**。首选「三层记忆」（MEM-01~06 规格在 `需求文档.md` §5.2 已明确，且不依赖外部推理服务即可测试 PostgresSaver/Store 持久化）。
>
> 工具链（codex-harness / Superpowers TDD）是**可选提速**，不是 Phase 3 的前置依赖——不阻塞业务实现。

- [ ] 三层记忆：`backend/db/` 连接 + PostgresSaver 短期记忆（MEM-01/02）
- [ ] 三层记忆：PostgresStore 长期记忆 + save/recall_memory 工具（MEM-03/05）
- [ ] 三层记忆：pgvector 语义检索（MEM-04，需 Milvus 或 pgvector 实际可用）
- [ ] 检查点清理（MEM-06）
- [ ] ReAct / 三层记忆 / SSE 自动化测试
