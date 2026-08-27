"""全栈 AI 智能体平台 - FastAPI 应用入口。"""

from fastapi import FastAPI

app = FastAPI(title="AI Agent Platform", version="0.1.0")


@app.get("/health")
async def health() -> dict[str, str]:
    """健康检查端点。"""
    return {"status": "ok"}


# SSE 流式对话与 RESTful API 在后续功能需求阶段接入
# 见 docs/reference/api-spec.yaml
