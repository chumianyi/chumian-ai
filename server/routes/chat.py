"""
聊天路由 - SSE 流式聊天、会话管理、模型列表
【核心模块】
未配置 ZHIPU_API_KEY 时返回 503 错误，绝不生成模拟回复
"""
import uuid
import json
from datetime import datetime, timezone
from typing import Optional, List, Dict, Any

from fastapi import APIRouter, Depends, HTTPException, status, Request
from fastapi.responses import StreamingResponse
import aiosqlite

from models import (
    ChatRequest, ConversationCreate, ConversationResponse,
    ConversationUpdate, MessageResponse, ModelInfo
)
from auth import get_current_user
from database import get_db, fetch_one, fetch_all, execute
from services.llm_service import chat_stream, get_available_models, get_model_type
from services.search_service import search, should_search, format_results_for_prompt
from config import settings

router = APIRouter()


def _now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def _generate_title(message: str, max_len: int = 50) -> str:
    """从用户消息生成会话标题（取前 max_len 个字符）"""
    title = message.strip().replace("\n", " ")
    if len(title) > max_len:
        title = title[:max_len] + "..."
    return title or "新对话"


def _sse_error(message: str) -> str:
    """构造 SSE 错误事件"""
    payload = {"type": "error", "message": message}
    return f"data: {json.dumps(payload, ensure_ascii=False)}\n\n"


# ===== SSE 流式聊天 =====
@router.post("/api/chat/stream")
async def chat_stream_endpoint(
    body: ChatRequest,
    request: Request,
    current_user: dict = Depends(get_current_user),
    db: aiosqlite.Connection = Depends(get_db),
):
    """
    SSE 流式聊天接口
    未配置 ZHIPU_API_KEY 时返回 HTTP 503 + SSE 错误事件
    """
    user_id = current_user["id"]
    conversation_id = body.conversation_id
    model = body.model or "glm-4-flash"

    # 未配置上游 API Key 时直接返回 503 错误
    if not settings.ZHIPU_API_KEY:
        error_msg = "未配置模型密钥，请在服务端配置 ZHIPU_API_KEY 环境变量"
        return StreamingResponse(
            iter([_sse_error(error_msg)]),
            media_type="text/event-stream",
            status_code=503,
            headers={
                "Cache-Control": "no-cache",
                "Connection": "keep-alive",
                "X-Accel-Buffering": "no",
            },
        )

    # 1. 获取或创建会话
    if conversation_id:
        conv = await fetch_one(
            db, "SELECT * FROM conversations WHERE id = ? AND user_id = ?",
            (conversation_id, user_id)
        )
        if not conv:
            raise HTTPException(status_code=404, detail="会话不存在")
    else:
        # 创建新会话
        conversation_id = uuid.uuid4().hex
        title = _generate_title(body.message)
        await execute(
            db,
            "INSERT INTO conversations (id, user_id, title, created_at) VALUES (?, ?, ?, ?)",
            (conversation_id, user_id, title, _now_iso()),
        )

    # 2. 保存用户消息
    user_msg_id = uuid.uuid4().hex
    await execute(
        db,
        """INSERT INTO messages (id, conversation_id, role, content, model, created_at)
           VALUES (?, ?, 'user', ?, ?, ?)""",
        (user_msg_id, conversation_id, body.message, model, _now_iso()),
    )

    # 3. 获取历史消息（最近 20 条，构造上下文）
    history_rows = await fetch_all(
        db,
        """SELECT role, content FROM messages
           WHERE conversation_id = ? ORDER BY created_at ASC LIMIT 20""",
        (conversation_id,),
    )
    messages = [{"role": r["role"], "content": r["content"]} for r in history_rows]

    # 如果有图片 URL，附加到用户消息
    if body.image_url:
        messages[-1]["content"] = f"{body.message}\n[图片: {body.image_url}]"

    # 4. 处理 Agent system prompt
    system_prompt = None
    if body.agent_id:
        agent = await fetch_one(
            db, "SELECT * FROM agents WHERE id = ?", (body.agent_id,)
        )
        if agent and agent.get("system_prompt"):
            system_prompt = agent["system_prompt"]

    if system_prompt:
        messages.insert(0, {"role": "system", "content": system_prompt})

    # 5. 联网搜索处理
    web_search_results = None
    need_search = body.web_search or should_search(body.message)

    if need_search:
        try:
            results = await search(body.message)
            if results:
                web_search_results = [r.dict() for r in results]
                # 将搜索结果注入 system prompt
                search_text = format_results_for_prompt(results)
                # 找到已有的 system 消息追加，或新建
                found_system = False
                for msg in messages:
                    if msg["role"] == "system":
                        msg["content"] += f"\n\n{search_text}"
                        found_system = True
                        break
                if not found_system:
                    messages.insert(0, {"role": "system", "content": search_text})
        except Exception:
            # 搜索失败不影响聊天
            pass

    # 6. 定义 SSE 事件生成器
    async def event_generator():
        full_content = ""
        full_think = ""
        tokens_used = 0
        image_url = None
        video_url = None

        try:
            # 如果有搜索结果，先发送 search_results 事件
            if web_search_results:
                payload = {
                    "type": "search_results",
                    "data": {"results": web_search_results[:5]}
                }
                yield f"data: {json.dumps(payload, ensure_ascii=False)}\n\n"

            # 调用 LLM 流式接口
            async for event_str in chat_stream(messages, model, web_search_results):
                # 检查客户端是否断开
                if await request.is_disconnected():
                    break

                yield event_str

                # 解析事件以累积内容用于保存
                try:
                    # event_str 格式: data: {json}\n\n
                    json_str = event_str[6:].strip()
                    event = json.loads(json_str)
                    event_type = event.get("type")
                    event_data = event.get("data", {})

                    if event_type == "think" and event_data.get("delta"):
                        full_think += event_data["delta"]
                    elif event_type == "content" and event_data.get("delta"):
                        full_content += event_data["delta"]
                    elif event_type == "image" and event_data.get("url"):
                        image_url = event_data["url"]
                        full_content += f"\n![图片]({image_url})\n"
                    elif event_type == "video_task" and event_data.get("url"):
                        video_url = event_data["url"]
                        full_content += f"\n[视频]({video_url})\n"
                    elif event_type == "done":
                        tokens_used = event_data.get("tokens_used", 0)
                except (json.JSONDecodeError, KeyError, IndexError):
                    pass

            # 7. 保存 AI 回复消息
            assistant_msg_id = uuid.uuid4().hex
            await execute(
                db,
                """INSERT INTO messages (id, conversation_id, role, content,
                   think_content, model, tokens_used, created_at)
                   VALUES (?, ?, 'assistant', ?, ?, ?, ?, ?)""",
                (assistant_msg_id, conversation_id, full_content or "(空回复)",
                 full_think or None, model, tokens_used, _now_iso()),
            )

            # 8. 如果是新会话或标题为默认，更新会话标题
            if not body.conversation_id:
                new_title = _generate_title(body.message)
                await execute(
                    db,
                    "UPDATE conversations SET title = ? WHERE id = ?",
                    (new_title, conversation_id),
                )

        except Exception as e:
            error_payload = {
                "type": "error",
                "data": {"message": f"聊天过程出错: {str(e)}"}
            }
            yield f"data: {json.dumps(error_payload, ensure_ascii=False)}\n\n"

    # 返回 SSE 响应
    return StreamingResponse(
        event_generator(),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "Connection": "keep-alive",
            "X-Accel-Buffering": "no",
        },
    )


# ===== 会话管理 =====
@router.get("/api/conversations", response_model=List[ConversationResponse])
async def list_conversations(
    current_user: dict = Depends(get_current_user),
    db: aiosqlite.Connection = Depends(get_db),
):
    """获取当前用户的会话列表（按创建时间倒序）"""
    rows = await fetch_all(
        db,
        "SELECT * FROM conversations WHERE user_id = ? ORDER BY created_at DESC",
        (current_user["id"],),
    )
    return [ConversationResponse(**r) for r in rows]


@router.get("/api/conversations/{conv_id}/messages", response_model=List[MessageResponse])
async def get_conversation_messages(
    conv_id: str,
    current_user: dict = Depends(get_current_user),
    db: aiosqlite.Connection = Depends(get_db),
):
    """获取指定会话的所有消息"""
    # 验证会话归属
    conv = await fetch_one(
        db, "SELECT id FROM conversations WHERE id = ? AND user_id = ?",
        (conv_id, current_user["id"]),
    )
    if not conv:
        raise HTTPException(status_code=404, detail="会话不存在")

    rows = await fetch_all(
        db,
        "SELECT * FROM messages WHERE conversation_id = ? ORDER BY created_at ASC",
        (conv_id,),
    )
    return [MessageResponse(**r) for r in rows]


@router.delete("/api/conversations/{conv_id}")
async def delete_conversation(
    conv_id: str,
    current_user: dict = Depends(get_current_user),
    db: aiosqlite.Connection = Depends(get_db),
):
    """删除会话及其所有消息"""
    conv = await fetch_one(
        db, "SELECT id FROM conversations WHERE id = ? AND user_id = ?",
        (conv_id, current_user["id"]),
    )
    if not conv:
        raise HTTPException(status_code=404, detail="会话不存在")

    # 删除消息
    await execute(db, "DELETE FROM messages WHERE conversation_id = ?", (conv_id,))
    # 删除会话
    await execute(db, "DELETE FROM conversations WHERE id = ?", (conv_id,))

    return {"message": "会话已删除"}


@router.put("/api/conversations/{conv_id}", response_model=ConversationResponse)
async def rename_conversation(
    conv_id: str,
    body: ConversationUpdate,
    current_user: dict = Depends(get_current_user),
    db: aiosqlite.Connection = Depends(get_db),
):
    """重命名会话"""
    conv = await fetch_one(
        db, "SELECT * FROM conversations WHERE id = ? AND user_id = ?",
        (conv_id, current_user["id"]),
    )
    if not conv:
        raise HTTPException(status_code=404, detail="会话不存在")

    await execute(
        db, "UPDATE conversations SET title = ? WHERE id = ?",
        (body.title, conv_id),
    )

    conv["title"] = body.title
    return ConversationResponse(**conv)


# ===== 模型列表 =====
@router.get("/api/models", response_model=List[ModelInfo])
async def list_models():
    """获取可用模型列表"""
    return get_available_models()
