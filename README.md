# 全栈 AI 智能体平台

基于 **LangGraph ReAct 推理循环** 与 **三层记忆系统** 的企业级 AI 智能体平台。以工具形式封装 RAG 能力供模型自主决策调用，配套短期 / 会话级 / 长期记忆架构实现跨会话个性化，并通过 SSE 流式交互提供 Agent 思考过程与工具调用进度的实时可视化。

---

## ✨ 核心特性

| 能力 | 说明 |
| :--- | :--- |
| **ReAct 推理引擎** | 基于 LangGraph StateGraph 构建"思考 → 行动 → 观察"循环，Agent 节点推理决策、Tools 节点执行工具 |
| **三层记忆** | 短期（PostgresSaver 检查点）· 会话级（PostgresStore）· 长期（pgvector 语义检索），支持中断恢复与跨会话个性化 |
| **RAG 工具封装** | 将检索能力封装为 LangChain Tool，由模型在 ReAct 循环中自主决策调用 |
| **SSE 流式交互** | Server-Sent Events 实时推送思考过程 / 工具调用进度，Vue 3 前端可视化 |
| **提示注入防御** | System Prompt 硬编码不可绕过的授权 / 安全指令，对用户输入过滤校验 |
| **全链路可观测** | 接入 LangSmith，监控 Token 消耗与调用耗时 |
| **CI 自愈闭环** | 门禁失败 → self-heal（Agent 修复核）→ 自动修复 → 人工 review，含安全护栏与防循环 |

---

## 📐 技术栈

| 层级 | 技术选型 | 版本 |
| :--- | :--- | :--- |
| 后端框架 | FastAPI | ≥ 0.115.0 |
| Agent 编排 | LangGraph | ≥ 0.2.50 |
| 核心框架 | LangChain | ≥ 0.3.0 |
| 关系数据库 | PostgreSQL | ≥ 14.0 |
| 向量数据库 | Milvus | ≥ 2.4 |
| ORM | SQLAlchemy | ≥ 2.0 |
| 检查点持久化 | langgraph-checkpoint-postgres | ≥ 2.0.0 |
| 长期记忆存储 | langgraph.store.postgres | ≥ 1.0 |
| 可观测性 | LangSmith | ≥ 0.1.0 |
| 前端框架 | Vue 3 | ≥ 3.4 |
| 流式协议 | Server-Sent Events (SSE) | — |
| 运行时 | Python | ≥ 3.10 |

---

## 🗂️ 项目结构

```
.
├── backend/                  # FastAPI 后端（含 tests/）
│   ├── main.py               # 应用入口（/health 健康检查）
│   ├── langgraph/            # ReAct 推理引擎（编排层）
│   ├── db/                   # 数据库 / 记忆访问层
│   ├── rag/                  # RAG 检索能力
│   └── tests/                # pytest 测试
├── frontend/                 # Vue 3 前端（SSE Client）
│   └── src/
├── docs/                     # 分层文档（架构/规范/设计/计划/参考）
├── scripts/                  # pre-commit 门禁等工具脚本
├── .github/workflows/        # CI（含自愈闭环）
├── .codex/                   # 自愈修复核配置
├── pyproject.toml            # 后端依赖与 Ruff 门禁
├── run_tests.sh              # 统一测试入口
├── 需求文档.md               # 需求规格（功能 / 技术栈 / 部署架构）
└── AGENTS.md                 # 项目规则导航
```

---

## 🚀 快速开始

### 环境要求
- Python ≥ 3.10（WSL 用户建议 venv，放 ext4 避开 NTFS 权限问题）
- Node.js ≥ 20（前端）
- PostgreSQL ≥ 14、Milvus ≥ 2.4（运行记忆 / RAG 时需要）

### 后端

```bash
# 创建虚拟环境并安装依赖（含 dev 组）
python -m venv .venv
# WSL 用户建议放在 /home 下避免 NTFS EPERM
# 墙内环境 pip 追加：-i https://pypi.tuna.tsinghua.edu.cn/simple

pip install -e ".[dev]"

# 启动服务
uvicorn backend.main:app --reload
```

### 前端

```bash
cd frontend
npm install
npm run dev
```

### 运行测试

```bash
# 统一测试入口（后端 ruff + pytest + 前端 lint）
bash run_tests.sh

# 前端 E2E（Windows 侧执行）
cd frontend && npm run test:e2e
```

### 健康检查

```bash
curl http://localhost:8000/health
# → {"status": "ok"}
```

---

## 🔄 CI 与自愈闭环

平台采取「门禁左移」策略，把质量约束前置到编码提交阶段，CI 作为兜底防线，失败时由 Agent 自动修复：

```
编码 → pre-commit 门禁（ruff+pytest+前端 lint，机械问题在此拦截）
        ↓ 通过
    commit → CI → 审查机制
        ↓ 通过                        ↓ 失败
    合并主分支                    self-heal（Agent 修复核）
                                   ├─ 机械问题 → ruff --fix 快路径（不调 Agent）
                                   └─ 语义残留 → Agent（DeepSeek）修复
                                        → 复检门禁 → heal/ 分支 + PR
                                        → 人工 review → 合并
```

**安全与可靠性设计**：
- **事件守卫**：仅 `push` 事件触发自愈，PR 事件不触发（避免竞态 / 裹挟 feature 代码 / 注入面）
- **断环机制**：修复推送到 `heal/` 专属分支，避免自愈无限循环
- **防静默失败**：修复无 diff 时强制失败而非"绿着消失"
- **修复范围对齐门禁**：Agent 修复含 pytest 全门禁，且明令禁止"删测试求绿"
- **最小权限 + 人工 review**：修复核 token 最小权限，PR 绝不自动合并

---

## 📚 文档导航

全部分层文档位于 `docs/`，按稳定度由低到高频更新：

- **架构 `docs/architecture/`**：系统概览与技术栈版本（`overview.md`）、模块边界与依赖规则（`boundaries.md`）、数据流与三层记忆 / SSE 契约（`data-flow.md`）
- **规范 `docs/conventions/`**：命名、错误处理、测试、日志（总览见其 `README.md`）
- **设计 `docs/design/`**：按功能组织的已实现 / 已批准 / 草稿设计
- **计划 `docs/plans/`**：当前迭代（`current-sprint.md`）与待办（`backlog.md`）
- **参考 `docs/reference/`**：API 规范（`api-spec.yaml`）与错误码（`error-codes.md`）
- **需求 `需求文档.md`**：功能需求、技术栈、部署架构、版本策略

> 严格以 `docs/` 文档为准，模糊处查阅原文，不臆测。

---

## 📋 项目状态

> 当前为 **骨架阶段**：约束层（门禁 / CI / 自愈 / 审查）已就绪并通过实测，三层记忆 / ReAct / SSE 业务代码待实现。

- [x] 项目骨架 + 文档分层
- [x] 后端门禁（Ruff 强化 / pytest）+ 前端门禁（ESLint）
- [x] CI 自愈闭环（6 场景实测通过）
- [x] 审查机制（异构模型 + 语义核对面）
- [x] 前端 Playwright E2E harness
- [ ] 三层记忆（短期 / 会话级 / 长期）
- [ ] ReAct 推理循环
- [ ] RAG 检索工具
- [ ] SSE 流式接口
- [ ] 部署架构（Nginx/CDN + FastAPI + PostgreSQL + Milvus）落地

---

## 📄 许可证

Licensed under the [MIT License](LICENSE).