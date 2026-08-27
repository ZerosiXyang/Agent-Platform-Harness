# 日志规范

## LangSmith 追踪

- 接入 LangSmith 实现全链路追踪（OBS-01）。
- 所有 LangGraph 节点必须携带 `metadata={"trace_id": "xxx"}` 打点。
- 使用 `@traceable(run_type="tool")` 追踪自定义工具。
- 监控 Token 消耗（OBS-02）、调用耗时（OBS-03）、错误追踪（OBS-04）。
- 新增代码未打点 LangSmith 追踪，CI 需拦截并要求重写。

## 日志级别

- `DEBUG`：向量检索参数、工具调用入参。
- `INFO`：请求级流程、记忆读写、检查点快照。
- `WARNING`：降级、重试、SSE 重连、检查点清理。
- `ERROR`：异常与失败。

## 通用

- 日志中不得记录敏感信息（token、用户隐私），遵循 NFR-11 脱敏。
- 结构化字段可读，便于 DSH / CI 自愈解析。
