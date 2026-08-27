#!/usr/bin/env bash
# 质量左移（P2）安装器：为当前仓库安装 pre-commit 前置门禁。
#
# 用法：  ./scripts/install-hooks.sh
#
# 作用： 生成 .git/hooks/pre-commit，委托给 scripts/pre-commit.sh
#	   （ruff check/format + pytest），让机械规范在 commit 前即被拦截。
# 适用： 新 clone 后 / 换机器后一条命令装好，避免人工漏装 hook。
#
# 无外部依赖（纯 bash + git）。在项目根运行。
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

# 目标 .git 目录（支持 worktree）
GIT_DIR="$(git rev-parse --git-dir 2>/dev/null || echo "$PROJECT_ROOT/.git")"
HOOK_DIR="$GIT_DIR/hooks"
HOOK_FILE="$HOOK_DIR/pre-commit"

mkdir -p "$HOOK_DIR"

# hook 内容：委托给仓库内 scripts/pre-commit.sh（经 git 根定位，跨机器可移植）
cat > "$HOOK_FILE" <<'EOF'
#!/usr/bin/env bash
# Quality left-shift hook (installed by scripts/install-hooks.sh).
# Delegates to scripts/pre-commit.sh (ruff check/format + pytest).
# See docs/conventions/code-review.md → 第 1 层 前置门禁（质量左移）。
set -euo pipefail
PROJECT_ROOT="$(git rev-parse --show-toplevel)"
exec "$PROJECT_ROOT/scripts/pre-commit.sh"
EOF

# WSL drvfs（NTFS）下 chmod 可能 EPERM，但 drvfs 文件默认所有位可执行，
# 故无需显式 chmod +x。先尝试 chmod，失败也不影响（hook 仍可执行）。
chmod +x "$HOOK_FILE" 2>/dev/null || true

echo "✔ pre-commit hook 已安装: $HOOK_FILE"
echo "  内容：ruff check/format + pytest，违规提交将被拦截。"
echo "  卸载：rm \"$HOOK_FILE\" 即可。"

# 自检：确认 hook 能被 git 识别
if [ -x "$HOOK_FILE" ] || [ -e "$HOOK_FILE" ]; then
  echo "✔ hook 就绪（将随每次 git commit 自动运行）"
else
  echo "⚠ hook 文件已写入但未被识别，请检查 $HOOK_FILE"
fi