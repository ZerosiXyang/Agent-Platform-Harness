# 功能：计费

**Status:** 📝 Draft

## 概述

按模型调用 / Token 用量计费（对应 OBS-05 成本分析）。

## 待定

- 计费维度（调用次数 / Token / 记忆存储）。
- 与 LangSmith 追踪（Token 消耗、调用耗时）的对账口径。
- 按项目 / 按用户 / 按时间维度的成本聚合方案。

## 相关需求

- OBS-02 Token 消耗监控（LangSmith 自动记录 LLM 调用 Token 用量与成本）。
- OBS-05 成本分析、OBS-06 成本阈值告警与异常检测。
