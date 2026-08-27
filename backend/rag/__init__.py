"""RAG 与 Milvus 向量库 - 工具声明与提示注入防御。

模块边界见 docs/architecture/boundaries.md：
- RAG 检索能力以 LangChain Tool 形式声明，由模型自主决策调用
- 必须包含提示注入防御逻辑
"""
