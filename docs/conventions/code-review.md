# 代码审查规范

> 说明代码审查的三层机制、检查清单与执行方式。审查者（独立 subagent）以此文档为唯一审查依据。

## 三层审查机制

| 层 | 执行者 | 职责 | 何时 |
|----|--------|------|------|
| 1. 自动化门禁 | 机器（ruff/eslint/pytest） | 静态规范 + 行为正确性，是审查的前提不是审查 | 每次编码后必跑 |
| 2. 两阶段 agent 审查 | 独立 subagent（delegate_task） | 主审查：Spec 合规 + 代码质量 | 每次编码任务完成后 |
| 3. 人工把关 | 用户 | 架构/依赖/需求冲突等决策点 | 命中清单即停下 |

核心原则：**审查者用 `delegate_task` 派发 fresh subagent，只给只读代码 + 规范文档路径，不给实现者的思考过程**，避免「自己审自己」。审查公信力来自信息隔离，而非换模型。

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

## 触发时机

- 每个 subagent 编码任务完成后 → 阶段 A + B 全跑
- Hermes 亲自编码的每轮收尾 → 至少跑阶段 B；涉及架构/记忆/安全则 A + B 全跑
- 简单改动（文案、注释）→ 只跑门禁，不派审查

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

输出结构化 JSON（approved + issues[] + summary）。
```
