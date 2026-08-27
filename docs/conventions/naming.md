# 命名规范

## 后端 (Python / FastAPI / LangGraph)

- 模块：`snake_case`。
- Graph 节点函数：动词开头（如 `agent_node` / `tools_node`）。
- State 字段：`snake_case`（TypedDict / Pydantic）。
- 工具：`@tool` 装饰后的函数名即工具名，保持语义清晰（如 `save_memory`、`recall_memory`）。
- 表模型：PascalCase 类名 + `snake_case` 表名。
- `thread_id` 全局唯一且长度 ≤255 字符。

## 前端 (Vue 3 / TypeScript)

- 组件：PascalCase（`ChatStream.vue`）。
- 组合式函数：`useXxx`。
- 变量 / Props：`camelCase`。

## 通用

- 禁止拼音、无意义缩写。
- 布尔变量用 `is_` / `has_` 前缀（后端）或 `is/has` 前缀（前端）。
- API 路径统一 `/api/` 前缀，RESTful 风格（需求文档 §6）。
- 健康探针 `/health`、`/healthz` 豁免 `/api/` 前缀（运维探针惯例，非业务 API）。
