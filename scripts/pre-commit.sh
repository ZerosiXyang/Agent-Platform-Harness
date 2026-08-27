#!/usr/bin/env bash
# 质量左移：pre-commit 前置门禁
# 每次 git commit 前运行，把「自动化门禁」从 CI/后置前移到编码提交时，
# 坏代码在进入 git 历史前就被拦截。对应 docs/conventions/code-review.md 第 1 层。
#
# 用法：
#   ./scripts/pre-commit.sh         全量（ruff + pytest），匹配 run_tests.sh 后端口
#   ./scripts/pre-commit.sh --fast  只检查有暂存改动的后端文件（ruff），不做全量 pytest
#
# 无外部依赖（仅需 venv 里的 ruff/pytest）。在项目根运行。
set -euo pipefail

# 定位项目根（脚本所在目录的上一级）
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

# 优先使用当前 shell 已激活的 python（须在项目 venv 下运行）；
# 若设置了 agent-platform venv 路径则用之；否则退回 python。
PY="python"
if [ -n "${VIRTUAL_ENV:-}" ] && [ -x "$VIRTUAL_ENV/bin/python" ]; then
  PY="$VIRTUAL_ENV/bin/python"
elif [ -x "/home/daly/.venvs/agent-platform/bin/python" ]; then
  PY="/home/daly/.venvs/agent-platform/bin/python"
fi

FAIL=0

echo "==> [pre-commit] 后端 Ruff 检查"
if ! "$PY" -m ruff check backend; then FAIL=1; fi

echo "==> [pre-commit] 后端 Ruff 格式"
if ! "$PY" -m ruff format --check backend; then FAIL=1; fi

if [ "${1:-}" != "--fast" ]; then
  echo "==> [pre-commit] pytest"
  if ! "$PY" -m pytest -q; then FAIL=1; fi
fi

if [ "$FAIL" -ne 0 ]; then
  echo ""
  echo "❌ [pre-commit] 检查未通过，commit 已拦截。请修复后再提交。"
  echo "   提示：机械问题可用 \`ruff check --fix backend\` 和 \`ruff format backend\` 自动修复。"
  exit 1
fi

echo "==> [pre-commit] 通过 ✅"
exit 0