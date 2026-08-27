# 系统架构概述

企业级全栈 AI 智能体（Agent）平台，基于 LangGraph 实现 ReAct 推理循环，以工具形式封装 RAG 能力供模型自主决策调用，配套三层记忆架构实现跨会话个性化，并通过 SSE 流式对话提供实时交互体验。

## 技术栈（版本要求）

| 层 | 技术 | 版本要求 |
|----|------|----------|
| 前端框架 | Vue 3（组合式 API + SSE） | ≥ 3.4 |
| 后端框架 | FastAPI | ≥ 0.115.0 |
| Agent 编排 | LangGraph | ≥ 0.2.50（推荐 1.0+） |
| 核心框架 | LangChain | ≥ 0.3.0（Core 推荐 1.0+） |
| ORM | SQLAlchemy | ≥ 2.0 |
| 向量数据库（RAG） | Milvus | ≥ 2.4 |
| 关系数据库 | PostgreSQL | ≥ 14.0（推荐 16+） |
| 检查点持久化 | langgraph-checkpoint-postgres | ≥ 2.0.0 |
| 长期记忆存储 | langgraph.store.postgres | ≥ 1.0（支持 pgvector） |
| 可观测性 | LangSmith | ≥ 0.1.0 |
| Python | Python | ≥ 3.10（推荐 3.12） |

完整版本矩阵与升级策略见 `../reference/` 与需求文档 §7。

## 架构图（一段话描述）

用户浏览器承载 Vue 3 前端，经 Nginx/CDN 反向代理，通过 SSE 与 FastAPI 应用层交互。
FastAPI 驱动 LangGraph 的 ReAct 推理引擎（`backend/langgraph/`），引擎通过 PostgresSaver
（短期记忆检查点）持久化会话状态，通过 PostgresStore（含 pgvector）承载长期记忆；
推理循环内模型自主决策调用 RAG 工具（`backend/rag/`，`@tool` 声明 + 提示注入防御），
RAG 检索走 Milvus 向量库。LangSmith 覆盖全链路可观测性。

## 模块职责

- `backend/langgraph/`：StateGraph 节点与边定义（ReAct 循环），禁止直连数据库。
- `backend/db/`：表结构与迁移脚本（PostgresSaver 检查点 / PostgresStore 长期记忆 / 应用层表）。
- `backend/rag/`：RAG 工具与提示注入防御，以 `@tool` 声明。
- `frontend/`：Vue 3 界面，流式对话、工具调用卡片、历史会话与记忆管理。

详见 `boundaries.md` 与 `data-flow.md`。
