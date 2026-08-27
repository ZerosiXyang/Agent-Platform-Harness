# 功能：检索（RAG）

**Status:** 📋 Approved

## 概述

RAG 检索能力，以 LangChain Tool 形式封装，由模型在 ReAct 循环中自主决策调用（REACT-04）。

## 设计要点

- 工具声明位于 `backend/rag/`，以 `@tool` 形式。
- 必须包含提示注入防御逻辑（REACT-05）：System Prompt 硬编码不可绕过的授权与安全指令 + 用户输入过滤校验。
- 检索结果经清理后再进入模型上下文。
- 向量库：Milvus（≥2.4）。

## 注意

- RAG 检索走 Milvus；长期记忆语义检索走 PostgreSQL 的 pgvector（两者用途不同，勿混淆）。

## 相关

- `backend/rag/AGENTS.md`
- `docs/conventions/testing.md`
- `docs/architecture/data-flow.md`
