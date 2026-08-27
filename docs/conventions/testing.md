# 测试规范

## 强制要求（TDD）

- 先写测试，再写实现（Superpowers TDD 流程）。
- ReAct 循环建立工具调用与推理路径的回归测试套件（REACT-06）。
- `backend/langgraph/` 的 ReAct 循环必须包含检查点持久化（PostgresSaver）、执行恢复（thread_id）回归测试。
- `backend/rag/` 的提示注入防御必须覆盖所有非法指令拦截回归测试（REACT-05）。

## 覆盖范围

- Graph 节点/边：单元 + 回归测试。
- 三层记忆系统：
  - Thread-level：会话中断后自 checkpoint 恢复上下文（MEM-01/02）。
  - User-level：会话级偏好读写（PostgresStore namespace）。
  - Cross-session：跨会话长期记忆写入 + pgvector 语义检索（MEM-03/04/05）。
- 检查点清理策略：定期清理过期检查点（MEM-06）。
- SSE：Mock 前端校验 8 种事件类型 JSON 结构与 Vue 3 Props 规范一致。

## 命令

- 全量测试：`bash run_tests.sh`
- 后端：`pytest --cov=backend`（从项目根运行）
