#!/usr/bin/env bash
# 全量测试：后端 Ruff + pytest，前端 lint
# 从项目根运行；使用 python -m 调用以保证跨平台（Windows + Linux CI）可用
set -euo pipefail

echo "==> 后端测试（Ruff + pytest）"
python -m ruff check backend
python -m ruff format --check backend
python -m pytest

echo "==> 前端 lint"
cd frontend
npm run lint
cd ..

echo "==> 全部通过 ✅"
