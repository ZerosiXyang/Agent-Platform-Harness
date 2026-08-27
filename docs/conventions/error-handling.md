# 错误处理规范

## 后端

- 使用自定义异常层级，禁止裸 `except`。
- FastAPI 接口错误返回结构化 JSON（`detail` 字段）。
- LangGraph 节点内异常应显式处理，避免中断 ReAct 循环（除非必须终止）。
- SSE 错误通过 `error` 事件推送：`{ message, agent? }`。

## RAG / 向量库

- Milvus 检索失败需降级：返回空结果或明确错误，不得让异常穿透进模型上下文。
- 提示注入拦截失败的请求必须记录并拒绝（`RAG_INJECTION_BLOCKED`）。

## 记忆系统

- PostgresSaver / PostgresStore 均需 `setup()` 初始化；初始化失败必须显式报错。
- checkpoint 缺失时返回 `MEM_CHECKPOINT_MISSING`。
- 长期记忆写入失败返回 `MEM_STORE_WRITE_FAILED`。

## 前端

- SSE 断开时自动重连并有退避（backoff）。
- 解析 SSE 失败不得导致页面崩溃；`error` 事件需可展示。

## 安全

- 日志与追踪中脱敏敏感用户信息（NFR-11）。
- 不同用户的记忆与会话数据严格隔离（NFR-10）。
