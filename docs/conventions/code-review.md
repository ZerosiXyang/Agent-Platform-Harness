# 代码审查规范

> 说明代码审查的三层机制、检查清单与执行方式。审查者（独立 subagent）以此文档为唯一审查依据。

## 三层审查机制

| 层 | 执行者 | 职责 | 何时 |
|----|--------|------|------|
| 1. 前置门禁（左移） | 机器（ruff/eslint/pytest，经 `scripts/pre-commit.sh`） | 静态规范 + 行为正确性，是审查的前提不是审查 | 每次 commit 前必跑（质量左移） |
| 2. agent 审查（兜底） | 独立 subagent（delegate_task） | 仅语义/架构/安全改动的 Spec 合规 + 代码质量 | 机械改动靠门禁；语义/架构/安全改动全跑 |
| 3. 人工把关 | 用户 | 架构/依赖/需求冲突等决策点 | 命中清单即停下 |

核心原则：**审查者用 `delegate_task` 派发 fresh subagent，只给只读代码 + 规范文档路径，不给实现者的思考过程**，避免「自己审自己」。审查公信力来自信息隔离，而非换模型。

**但公信力 ≠ 语义保真。** 信息隔离的代价是审查者看不到需求意图与跨文件调用链，只能验「合不合规范」，验不了「修复是否真解了原问题」——机械修复够用，语义修复会失守。为补上语义保真，审查者按下文「裁决规则」可读取以下「最小必需上下文」（都是**事实上下文**，非实现者思考过程，读取不伤公信力）：

- 需求文档中本轮改动对应的功能点条目（`需求文档.md` 的 REACT-xx/MEM-xx/OBS-xx/API-xx）
- 被改动文件的上游/下游调用定义（`read_file` 读调用方与被调用方签名，不定向来源意图）
- 相关接口契约（`docs/reference/api-spec.yaml` / `docs/architecture/data-flow.md` 事件字段）
- 相关表结构/数据模型（`backend/db/` schema 定义）
- 目标测试（改动应通过 / 应新增的测试用例，用于交叉核对修复确实消除缺陷）

裁决规则：**强触发**——当改动目标是「缺陷修复」或「语义行为变更」（非纯机械/风格改动）时，审查者**必须**读需求文档对应功能点交叉核对，确认改动确实消除缺陷而非掩盖；不得依赖「在需要时」这类主观判断。当某 issue 的严重性判定依赖上文所列最小必需上下文时，读取后再定性。**禁止反向**：不从实现者的对话、commit message 或私有笔记索取或推断意图——仅限上文所列事实上下文（功能点条目／调用签名／接口契约／表结构／目标测试）作为语义核对的合法来源。

## 第 1 层：自动化门禁

```bash
bash run_tests.sh   # 后端 ruff + pytest + 前端 eslint
```

门禁只回答「能不能跑、符不符合静态规范」。审查时假定门禁已绿。

## 第 2 层：两阶段 agent 审查

### 阶段 A — Spec 合规审查（审「做对了没」）

逐项核对，不满足即记 issue：

1. 需求文档功能点（REACT-xx / MEM-xx / OBS-xx / API-xx / NFR-xx）是否全覆盖
2. 是否违反 `docs/architecture/boundaries.md` 模块允许/禁止表（如 `langgraph/` 禁止直连 `db`/`rag`）
3. 依赖方向是否单向（上层→下层，无反向 import）
4. SSE 事件是否符合 `data-flow.md` 的 8 种契约字段
5. 命名是否符合 `docs/conventions/naming.md`（thread_id ≤255、@tool 命名、`/api/` 前缀、is_/has_ 前缀）
6. 依赖版本是否满足 `需求文档.md` §7 版本矩阵下限

### 阶段 B — 代码质量审查（审「做得好不好」）

仅在阶段 A 通过后执行，逐项核对：

1. DRY / YAGNI（无重复逻辑、无投机性「未来扩展」）
2. 错误处理符合 `docs/conventions/error-handling.md`（自定义异常层级、禁裸 except、Milvus 降级、提示注入拦截记录）
3. 日志符合 `docs/conventions/logging.md`（trace_id / @traceable 打点、日志级别、脱敏 NFR-11）
4. 测试符合 `docs/conventions/testing.md`（TDD：先写失败测试）
5. 安全：提示注入防御（REACT-05）、用户数据隔离（NFR-10）、敏感信息脱敏（NFR-11）
6. CI / 脚本：无死代码、重复 step、错误的 if 语义、逻辑漏洞

## 第 3 层：人工把关（agent 不得擅自决定）

命中以下任一，停下交用户：

1. 架构边界变更（修改 `boundaries.md` 允许/禁止表）
2. 新增/删除依赖（`pyproject.toml` / `package.json`）
3. 需求文档 vs 现实冲突（如 `langgraph-store-postgres` 包不存在）——带证据给替代方案
4. 数据模型 / 表结构变更（`backend/db/` 迁移）
5. 技术选型与版本升级（§7 版本矩阵）

## 输出契约（JSON schema）

审查 subagent 必须返回结构化结果，由 `delegate_task` 的 `output_schema` 强制校验：

```json
{
  "approved": false,
  "issues": [
    {
      "file": "backend/rag/retriever.py",
      "line": 42,
      "severity": "blocking",
      "category": "error-handling",
      "detail": "Milvus 检索异常直接抛出，未降级，违反 error-handling.md",
      "suggestion": "try/except 捕获后返回空结果并记录 RAG_RETRIEVE_FAILED"
    }
  ],
  "summary": "1 blocking + 2 warning"
}
```

- `severity`：`blocking`（须修复才能通过）或 `warning`（可接受但建议改进）
- `approved = true` 仅当无 blocking 项；有 warning 时应在 summary 说明

## 触发时机（质量左移后的分工）

**默认前提：门禁已前置到 pre-commit**（`scripts/pre-commit.sh`，已安装 `.git/hooks/pre-commit`），机械规范（ruff 未使用导入/类型/格式）在 commit 前即被拦截。因此 agent 审查**退居兜底层**，只在机器查不了或影响大的地方介入，避免对每处机械改动重复浪费 agent 调用。

- 机械/风格改动（ruff 可查的 F401/ANN/格式、注释、文案、重命名无行为变更）→ **只靠前置门禁**（pre-commit + CI），不派 agent 审查——审查成本已左提给机器
- 语义改动（缺陷修复、重构行为变更、新功能、逻辑分支）→ **阶段 A + B 全跑**（用「最小必需上下文/语义核对面」强触发核对是否真解需求）
- 架构/记忆/安全相关改动 → **阶段 A + B 全跑**，且命中第 3 层人工把关清单即停
- Hermes / subagent 编码每轮收尾：先过 pre-commit 门禁，再按上述分类决定是否派语义/架构审查

核心变化：**门禁左移后，agent 审查从「每次编码后的例行两层」降级为「仅语义/架构/安全改动的兜底一层」**——这正是降低总成本的来源（机械问题不再消耗 agent 审查）。

## 审查者须知（试审经验，2026-08-26）

1. **脱敏陷阱**：Hermes 会对疑似密钥的字符串（如 `postgresql://user:pass@`）做脱敏显示成 `***`。
   审查者看到的 `***` 可能不是文件真实内容。报「密码是字面量 ***」前，须先核实文件真实字节
   （如 `python3 -c "print('***' in open(f).read())"`），避免误报。
2. **只读原则**：审查 subagent 禁止修改任何文件，只输出 JSON 审查结果。
3. **文档漂移也是 issue**：规范文档与实际配置不一致（如命令过期、路径失效）同样要报，category 用 `doc-drift`。
4. **docstring 字面量陷阱**：`__init__.py` 的 docstring 里引用 `@tool` 等装饰器名，会被 grep 类 CI 检查误命中，
   审查时留意这类「静态检查 vs 注释文字」的误判。

## 附录：审查 prompt 模板

### 阶段 A prompt

```
对项目本轮改动做 Spec 合规审查（阶段 A）。只读审查，禁止修改任何文件。

项目根：<PROJECT_ROOT>
本轮改动文件清单：<FILES>
审查依据（用 read_file 阅读）：docs/architecture/boundaries.md、data-flow.md、overview.md、
docs/conventions/naming.md、testing.md、需求文档.md

阶段 A 检查清单：
1. 需求功能点全覆盖（REACT/MEM/OBS/API/NFR）
2. 不违反 boundaries.md 允许/禁止表
3. 依赖方向单向
4. SSE 8 种事件契约
5. 命名规范（naming.md）
6. §7 版本矩阵下限

语义核对面：当⚠️（1）判断某功能点是否实现、⚠️（2）判断是否符合边界、⚠️（5）SSE 契约时，
若仅凭改动本身无法确证「是否真解了原需求」，须读改动对应功能点条目 + 相关接口契约交叉核对，
再定性 issue 严重性。合法上下文仅限主段「最小必需上下文」清单（功能点条目／调用签名／接口契约／
表结构／目标测试）——禁止从实现者对话、commit message、私有笔记推断意图，只读事实上下文。

输出结构化 JSON（approved + issues[] + summary）。
```

### 阶段 B prompt

```
对项目本轮改动做代码质量审查（阶段 B）。只读审查，禁止修改任何文件。

项目根：<PROJECT_ROOT>
本轮改动文件清单：<FILES>
审查依据（用 read_file 阅读）：docs/conventions/error-handling.md、logging.md、testing.md、naming.md

阶段 B 检查清单：
1. DRY/YAGNI
2. 错误处理（error-handling.md）
3. 日志打点（logging.md，trace_id/@traceable）
4. 安全（REACT-05 / NFR-10 / NFR-11）
5. 测试（TDD）
6. CI/脚本死代码与逻辑漏洞

语义核对面：当本次改动删除了符号/参数/分支，或重构了核心逻辑，或改动目标是「缺陷修复/语义行为变更」时，**必须** read 被改动文件的上游调用方确认删除不破坏契约，并按上方主段「裁决规则」的强触发条款读需求文档对应功能点 + 目标测试交叉核对，确认改动确实消除缺陷而非掩盖。合法上下文仅限主段「最小必需上下文」清单（功能点条目／调用签名／接口契约／表结构／目标测试）——禁止从实现者对话、commit message、私有笔记推断意图。

输出结构化 JSON（approved + issues[] + summary）。
```
