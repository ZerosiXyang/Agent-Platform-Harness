# 错误码

> 参考层，自动生成。当前为依据需求文档语义整理的错误码，待实现后由代码常量导出替换。

| 错误码 | 含义 | 层 |
|--------|------|----|
| `RAG_INJECTION_BLOCKED` | 提示注入被拦截 | `backend/rag/` |
| `RAG_RETRIEVE_FAILED` | Milvus 向量检索失败（降级） | `backend/rag/` |
| `MEM_CHECKPOINT_MISSING` | checkpoint 缺失 | `backend/db/` |
| `MEM_STORE_WRITE_FAILED` | 长期记忆（PostgresStore）写入失败 | `backend/db/` |
| `MEM_STORE_SEARCH_FAILED` | 长期记忆语义检索（pgvector）失败 | `backend/db/` |
| `THREAD_NOT_FOUND` | 会话（thread_id）不存在 | `backend/db/` |
| `THREAD_ID_TOO_LONG` | thread_id 超过 255 字符 | `backend/langgraph/` |

补充规则详见 `docs/conventions/error-handling.md`。
