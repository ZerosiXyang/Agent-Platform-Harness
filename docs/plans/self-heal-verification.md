# 自愈闭环验证记录

> 记录 2026-08 对「制造 bug → 检测 → Codex 自愈 → 复检」闭环的实际验证结果，
> 以及需求文档中 `dsh` / `codex` 命令语法与当前环境的真实差异。

## 验证过程

| 阶段 | 操作 | 结果 |
|------|------|------|
| 1. 制造 bug | 在 `backend/main.py` 加入未使用导入 `import os` + `import json` | — |
| 2. 检测 | `ruff check .` | ✅ 捕获 3 错误（F401×2 + I001） |
| 3. Codex 只读分析 | `codex exec -s read-only "..."` | ✅ 正确定位 3 处、给出 2 方案、遵守「不改文件」 |
| 4. Codex 修复 | `codex exec -s workspace-write "修复..."` | ✅ apply patch 删 2 行，`ruff check` 复检通过 |
| 5. 最终确认 | `ruff check` + `ruff format --check` | ✅ 全部通过 |

## 结论

Codex 无头模式在本项目可用，能完整完成「定位 → 修复 → 复检」的自愈闭环，
且自觉遵守沙箱边界（read-only 不改文件，workspace-write 才写）。

## 需求文档 vs 当前环境的命令差异

需求文档中的命令是概念性描述，真实环境语法如下：

| 需求文档写法 | 当前真实语法（已验证） |
|--------------|------------------------|
| `codex exec --plan '...'` | `codex exec "prompt"`（prompt 直接作位置参数） |
| `--approval-mode auto` | `--approve-for-me`（或 `-s` 沙箱模式控制） |
| `--sandbox` | `-s read-only` / `-s workspace-write` / `-s danger-full-access` |
| `--worktree feature/auto-heal` | 需自行 `git checkout -b feature/auto-heal` |

## 关于 `dsh`

需求文档里的 `dsh run --headless --plugin error-router --parallel --task1` 是**编排层 DSL 概念**，
当前环境的 `dsh`（DeepSeek Harness v0.1.0-rc.7）用法是 `dsh --profile <name>`，
**并无** `run` / `--plugin error-router` / `--parallel` / `--task1` 这些参数。

因此自愈闭环的「DSH 编排」环节在当前环境尚未接入真实编排器，
CI 里的 `self-heal` 已退化为「直接调用 codex exec」的可运行版本，
待后续接入真正的编排工具（或 DSH 对应 profile）后再补回编排层。
