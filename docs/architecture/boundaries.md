# 模块边界与依赖规则

## 边界

| 模块 | 允许 | 禁止 |
|------|------|------|
| `backend/langgraph/` | 定义 StateGraph 节点/边、ReAct 循环、检查点持久化与执行恢复 | 直连数据库；直接 import db/rag 数据访问层 |
| `backend/db/` | 定义 SQLAlchemy 表结构、迁移脚本、Checkpointer/Store 封装 | 实现业务/推理逻辑 |
| `backend/rag/` | `@tool` 声明 RAG、提示注入防御、Milvus 检索 | 定义 LangGraph 图结构 |

## 依赖方向

```
frontend/ ──SSE──▶ FastAPI 应用层
                     │ 驱动
                     ▼
              backend/langgraph/  (ReAct 循环 + 检查点 + Store)
                     │ 模型自主决策调用
                     ▼
              backend/rag/  (@tool + 提示注入防御 + Milvus)
                     │
                     ▼
              backend/db/  (PostgresSaver / PostgresStore / 应用层表)
```

## 依赖规则

- 上层可依赖下层，下层不得反向依赖上层。
- `langgraph` 对 `db` / `rag` 的访问仅通过接口 / 依赖注入。
- 跨模块改动必须先阅读目标目录的 `AGENTS.md`。
- PostgresSaver 与 PostgresStore 数据隔离、能力互补：前者短期会话状态，后者长期用户记忆。
