# 功能：认证

**Status:** ✅ Implemented

## 概述

用户身份认证与登录态管理（NFR-09）。

## 实现要点

- 基于 JWT 的用户认证与 State 级授权。
- 认证信息注入 LangGraph 请求上下文（`configurable.user_id`），用于记忆归属与数据隔离。
- 不同用户的记忆与会话数据严格隔离（NFR-10）。

## API

- 会话管理接口均以 `user_id` 区分数据归属（`/api/threads` 等，见 `../reference/api-spec.yaml`）。

## 相关

- `docs/architecture/data-flow.md`
- 记忆归属：user-level / cross-session 记忆按 user_id 写入 PostgresStore。
