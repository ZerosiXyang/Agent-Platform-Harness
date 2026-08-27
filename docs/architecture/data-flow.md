# 数据流转图

## 一次对话请求的流转

```
用户输入 (Vue 3)
   │  GET /api/chat/stream?thread_id&message&user_id
   ▼
FastAPI SSE 事件生成器 (StreamingResponse, astream_events v2)
   │  推送事件流（含 8 种事件类型，见下）
   ▼
LangGraph ReAct 循环 (backend/langgraph/)
   │ 模型自主决策（Thought → Action → Observation）
   ├──▶ 调用 RAG 工具 (backend/rag/, @tool)
   │       │  提示注入防御（System Prompt 硬编码安全指令 + 输入过滤）
   │       ▼
   │     Milvus 向量检索（RAG）
   │
   ├──▶ 短期记忆 (PostgresSaver 检查点, backend/db/)
   │       thread-level，thread_id ≤255 字符，节点执行后自动快照
   │
   └──▶ 长期记忆 (PostgresStore, backend/db/)
           user-level + cross-session，namespace + key + pgvector 语义检索
```

## 三层记忆架构

| 记忆层级 | 存储机制 | 作用域 | 用途 |
|----------|----------|--------|------|
| 短期记忆（Thread-level） | PostgresSaver（检查点） | 单线程（thread_id） | 多轮对话、会话状态、执行断点 |
| 会话级记忆（User-level） | PostgresStore（namespace） | 用户级（user_id 下所有 thread） | 当前会话周期内的偏好与状态 |
| 长期记忆（Cross-session） | PostgresStore + 向量检索 | 跨会话（user_id 全局） | 用户画像、事实记忆、偏好持久化 |

## SSE 事件契约

SSE 事件 JSON 结构必须符合 Vue 3 前端渲染组件的 Props 规范，共 8 种事件类型：

| 事件类型 | 数据字段 |
|----------|----------|
| `agent_started` | `{ agent, timestamp }` |
| `agent_thinking` | `{ agent, thought }` |
| `tool_called` | `{ agent, tool, input }` |
| `tool_result` | `{ agent, tool, result }` |
| `agent_completed` | `{ agent, output }` |
| `workflow_completed` | `{ result }` |
| `error` | `{ message, agent? }` |
| `token` | `{ content, delta }` |

统一格式：`data: {JSON}\n\n`，`media_type="text/event-stream"`。
