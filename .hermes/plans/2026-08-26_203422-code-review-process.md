# 编码后审查机制 Implementation Plan

> **For Hermes:** 用本 plan 明确「编码完成后谁审查、审查什么、如何触发」。执行时配合 `subagent-driven-development` 技能做两阶段 agent 审查。

**Goal:** 为「Hermes 替代 dsh 做编排编码」的流程补上缺失的代码审查环节，明确三层审查的责任归属与执行标准。

**Architecture:** 三层审查漏斗——① 自动化门禁（机器，底线）→ ② 两阶段 agent 审查（独立 subagent，主审查）→ ③ 人工把关（用户，决策点）。只有前一层通过才进入下一层。

**Tech Stack:** delegate_task（subagent 两阶段审查）、ruff/eslint/pytest（已有门禁）、docs/ 规范文档（审查依据）

---

## 背景与现状

项目目前**没有**任何真正意义上的代码审查（code review）。现存把关仅有自动化门禁：

| 现有门禁 | 性质 | 局限 |
|----------|------|------|
| `ruff check` / `ruff format` | 静态 lint + 类型提示(ANN) + 禁未使用导入(F401) | 只管格式与语法，不看逻辑 |
| `eslint`（前端） | 静态 lint | 同上 |
| `pytest --cov=backend` | 行为正确性 | 只看测试是否通过，测试本身可能漏 |
| CI `langsmith-check` | 静态 grep 检查 trace_id 打点 | 只看打点字符串 |
| CI `self-heal` | Codex 失败后自动修复 | 是「修」不是「审」，且依赖真实 GitHub |

**空缺**：Hermes（或 subagent）编码后，没有独立角色审查——逻辑正确性、架构边界遵守、DRY/YAGNI、安全（提示注入/脱敏/数据隔离）、命名与错误处理规范，全部无人把关。

**审查依据（已存在，直接引用）**：
- `docs/architecture/boundaries.md` —— 模块允许/禁止表、依赖方向
- `docs/architecture/data-flow.md` —— SSE 8 种事件契约、三层记忆
- `docs/conventions/naming.md` / `error-handling.md` / `testing.md` / `logging.md`
- `docs/reference/error-codes.md` —— 错误码常量
- 需求文档 `需求文档.md` —— REACT-xx / MEM-xx / OBS-xx / NFR-xx 功能点

---

## 三层审查机制

### 第 1 层：自动化门禁（机器，每次编码后必跑）

- 后端：`ruff check backend` + `ruff format --check backend` + `pytest`
- 前端：`npm run lint`
- 统一入口：`bash run_tests.sh`
- **职责**：只回答「能不能跑、符不符合静态规范」。**不是审查，是审查的前提。**

### 第 2 层：两阶段 agent 审查（主审查，独立 subagent）

用 `delegate_task` 派发 **fresh subagent**（无实现者上下文，避免「自己审自己」），分两阶段：

**阶段 A — Spec 合规审查（Spec Compliance Review）**
审查者核对实现是否满足规格，检查清单：
- [ ] 对应需求文档功能点（REACT-xx/MEM-xx/OBS-xx/API-xx/NFR-xx）是否全部覆盖
- [ ] 是否遵守 `boundaries.md` 的模块允许/禁止表（如 langgraph 禁止直连 db/rag）
- [ ] 依赖方向是否单向（上层→下层，无反向 import）
- [ ] SSE 事件 JSON 是否符合 8 种事件契约与字段
- [ ] 命名是否符合 `naming.md`（thread_id ≤255、@tool 命名、PascalCase/camelCase）

**阶段 B — 代码质量审查（Code Quality Review）**
（仅在阶段 A 通过后执行）检查清单：
- [ ] DRY / YAGNI（无重复逻辑、无投机性"未来扩展"）
- [ ] 错误处理符合 `error-handling.md`（自定义异常层级、禁裸 except、Milvus 降级、提示注入拦截记录）
- [ ] 日志符合 `logging.md`（LangSmith 打点 trace_id/@traceable、日志级别、脱敏 NFR-11）
- [ ] 测试符合 `testing.md`（TDD：先写失败测试）
- [ ] 安全：提示注入防御（REACT-05）、用户数据隔离（NFR-10）、敏感信息脱敏（NFR-11）
- [ ] ruff/eslint 已通过（门禁前置）

**审查产物**：每个 subagent 返回 `{approved: bool, issues: [{file, line, severity, suggestion}]}`。
- 两个阶段均 approved → 任务完成
- 任一阶段有 blocking issue → 修复后重新审查（不跳过）

### 第 3 层：人工把关（用户，仅决策点）

以下情况**必须**交用户裁决，agent 不得擅自决定：
1. 架构边界变更（修改 `boundaries.md` 的允许/禁止表）
2. 新增/删除依赖（`pyproject.toml` / `package.json`）
3. 需求文档 vs 现实冲突（如已发生的 `langgraph-store-postgres` 不存在）——带证据给替代方案
4. 数据模型 / 数据库表结构变更（`backend/db/` 迁移）
5. 技术选型与版本升级（§7 版本矩阵）

---

## 落地任务

### Task 1: 新增审查标准文档

**Objective:** 将两层 agent 审查的检查清单固化为项目规范文档，供 subagent 审查时引用。

**Files:**
- Create: `docs/conventions/code-review.md`

**内容**：上述「阶段 A / 阶段 B」检查清单 + 三层机制说明 + 第 3 层人工把关清单。

**Step 1:** 写入 `docs/conventions/code-review.md`（内容即本 plan 第 2 层清单的展开版）。
**Step 2:** 在 `docs/conventions/README.md` 的规范索引表新增一行 `代码审查规范 | code-review.md`。
**Step 3:** 验证：`read_file` 确认文档存在、索引表已更新。

### Task 2: 定义 subagent 审查 prompt 模板

**Objective:** 让每次审查派发的 prompt 一致、可复用，审查者拿到完整检查清单与文件路径。

**Files:**
- Create: `.hermes/plans/review-prompts.md`（或作为 code-review.md 的附录）

**内容**：两个可复制的 prompt 模板——
- 阶段 A prompt：附 `boundaries.md`/`data-flow.md`/`naming.md` 路径 + spec 检查清单 + 输出 JSON schema
- 阶段 B prompt：附 `error-handling.md`/`logging.md`/`testing.md` 路径 + 质量检查清单 + 输出 JSON schema

**Step 1:** 写入模板，明确 subagent 的 `output_schema`（`approved`、`issues[]`）。
**Step 2:** 验证：模板包含所有必需文件路径与 JSON 输出契约。

### Task 3: 接入工作流（明确触发时机）

**Objective:** 规定「编码后何时触发审查」，避免审查被跳过。

**Files:**
- Modify: `docs/plans/current-sprint.md`（新增「审查机制」条目）

**规则**：
- 每个 subagent 任务完成后 → 触发阶段 A + 阶段 B
- Hermes 亲自编码的每轮收尾（如本次清理迭代）→ 至少触发一次阶段 B 审查
- 提交 commit 前 → 门禁（第 1 层）必须绿
- 涉及第 3 层清单的变更 → 停下交用户

**Step 1:** 在 `current-sprint.md` 追加审查机制条目。
**Step 2:** 验证：条目与 backlog 对齐。

### Task 4: 试点跑一次审查（验证机制可用）

**Objective:** 用本轮清理迭代的改动做一次真实审查，验证两阶段流程跑得通。

**Files:** 无新文件（只读审查本轮已改的 `backend/`、`pyproject.toml`、CI、`run_tests.sh`）

**Step 1:** 派发阶段 A subagent（spec 合规）审查本轮改动。
**Step 2:** 派发阶段 B subagent（代码质量）审查。
**Step 3:** 汇总 issue，逐条确认或修复。
**Step 4:** 验证：产出审查报告，记录到本轮收尾。

---

## 验证标准

- [ ] `docs/conventions/code-review.md` 存在且含完整检查清单
- [ ] `docs/conventions/README.md` 索引已更新
- [ ] 审查 prompt 模板含 JSON 输出 schema
- [ ] 至少完成一次「阶段 A + 阶段 B」真实审查，产物为结构化 issue 列表
- [ ] 门禁 `bash run_tests.sh` 仍全绿（审查机制不破坏现有验证）

## 风险 / 权衡 / 开放问题

1. **审查者无上下文**：subagent 不知道实现者的决策背景，可能误报。缓解：prompt 附带需求文档 + 设计文档路径，让其以文档为唯一事实源。
2. **审查成本**：每任务两次 subagent 派发增加耗时。权衡：对「简单任务」可只跑阶段 B；「涉及架构/记忆/安全」的必须两阶段全跑。
3. **「自己审自己」边界**：Hermes 亲自编码时，审查 subagent 与编码者是否为同一上下文？须确保 `delegate_task` 的审查者拿到的是**只读代码 + 文档**，不含实现者的思考过程，避免审查者被实现者思路带偏。
4. **开放问题**：是否需要把两阶段审查固化成 CI job（而非仅在 Hermes 会话内手动派发）？当前项目无 git remote，CI 尚无法真正运行，故先落在会话内流程，待 GitHub 接入后再上移。
