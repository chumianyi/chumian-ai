"""
LLM 服务 - 智谱 GLM 流式调用
支持模型：chat/vision/image/video 四类
未配置 ZHIPU_API_KEY 时返回错误事件，绝不生成模拟回复
"""
import json
import httpx
from typing import AsyncGenerator, List, Dict, Any, Optional

from config import settings


# ===== 模型定义 =====
MODEL_CATALOG = {
    "glm-4-flash": {
        "name": "GLM-4-Flash",
        "description": "高速通用对话模型，响应快",
        "type": "chat",
    },
    "glm-4-flash-250414": {
        "name": "GLM-4-Flash-250414",
        "description": "GLM-4-Flash 2025年4月版本",
        "type": "chat",
    },
    "glm-4.7-flash": {
        "name": "GLM-4.7-Flash",
        "description": "新一代高速推理模型",
        "type": "chat",
    },
    "glm-z1-flash": {
        "name": "GLM-Z1-Flash",
        "description": "深度思考模型，支持长链推理",
        "type": "chat",
    },
    "glm-4v-flash": {
        "name": "GLM-4V-Flash",
        "description": "视觉理解模型，支持图片输入",
        "type": "vision",
    },
    "glm-4.6v-flash": {
        "name": "GLM-4.6V-Flash",
        "description": "新一代视觉理解模型",
        "type": "vision",
    },
    "glm-4.1v-thinking-flash": {
        "name": "GLM-4.1V-Thinking-Flash",
        "description": "视觉思考模型，边看边想",
        "type": "vision",
    },
    "cogview-3-flash": {
        "name": "CogView-3-Flash",
        "description": "文生图模型，生成高质量图片",
        "type": "image",
    },
    "cogvideox-flash": {
        "name": "CogVideoX-Flash",
        "description": "文生视频模型，生成短视频",
        "type": "video",
    },
}


def get_available_models() -> List[Dict[str, Any]]:
    """获取可用模型列表"""
    return [
        {
            "id": mid,
            "name": info["name"],
            "description": info["description"],
            "type": info["type"],
            "supports_stream": info["type"] in ("chat", "vision"),
        }
        for mid, info in MODEL_CATALOG.items()
    ]


def get_model_type(model: str) -> str:
    """获取模型类型"""
    return MODEL_CATALOG.get(model, {}).get("type", "chat")


# ===== SSE 事件构造 =====
def _sse_event(event_type: str, data: Any) -> str:
    """构造 SSE 事件格式：data: {json}\\n\\n"""
    payload = {"type": event_type, "data": data}
    return f"data: {json.dumps(payload, ensure_ascii=False)}\n\n"


# ===== 真实智谱 API 调用 =====
async def _zhipu_chat_stream(
    messages: List[Dict[str, str]],
    model: str,
    web_search_results: Optional[List[Dict]] = None,
) -> AsyncGenerator[str, None]:
    """
    调用智谱 GLM SSE 流式接口
    转发 think/content 事件
    """
    url = f"{settings.ZHIPU_BASE_URL}/chat/completions"
    headers = {
        "Authorization": f"Bearer {settings.ZHIPU_API_KEY}",
        "Content-Type": "application/json",
    }

    # 构造请求消息
    request_messages = []

    # 如果有搜索结果，注入到 system prompt
    if web_search_results:
        search_context = "\n\n".join([
            f"[{i+1}] {r.get('title', '')}\n{r.get('snippet', '')}\n来源: {r.get('url', '')}"
            for i, r in enumerate(web_search_results[:5])
        ])
        system_msg = (
            f"你是一个有帮助的 AI 助手。以下是联网搜索到的参考信息，"
            f"请结合这些信息回答用户问题，并在回答中引用来源：\n\n{search_context}"
        )
        request_messages.append({"role": "system", "content": system_msg})

    request_messages.extend(messages)

    payload = {
        "model": model,
        "messages": request_messages,
        "stream": True,
    }

    last_chunk = {}
    try:
        async with httpx.AsyncClient(timeout=120.0) as client:
            async with client.stream("POST", url, headers=headers, json=payload) as response:
                if response.status_code != 200:
                    error_text = await response.aread()
                    yield _sse_event("error", {
                        "message": f"上游 API 错误 {response.status_code}: {error_text.decode('utf-8', errors='ignore')}"
                    })
                    return

                async for line in response.aiter_lines():
                    if not line or not line.startswith("data: "):
                        continue

                    data_str = line[6:]
                    if data_str.strip() == "[DONE]":
                        break

                    try:
                        chunk = json.loads(data_str)
                        last_chunk = chunk
                    except json.JSONDecodeError:
                        continue

                    choices = chunk.get("choices", [])
                    if not choices:
                        continue

                    delta = choices[0].get("delta", {})

                    # 处理思考内容（智谱 reasoning_content 字段）
                    if "reasoning_content" in delta and delta["reasoning_content"]:
                        yield _sse_event("think", {"delta": delta["reasoning_content"]})

                    # 处理正文内容
                    if "content" in delta and delta["content"]:
                        yield _sse_event("content", {"delta": delta["content"]})

                # 完成事件
                usage = last_chunk.get("usage", {}) if last_chunk else {}
                yield _sse_event("done", {
                    "conversation_id": None,
                    "model": model,
                    "tokens_used": usage.get("total_tokens", 0),
                })

    except httpx.TimeoutException:
        yield _sse_event("error", {"message": "上游 API 请求超时"})
    except Exception as e:
        yield _sse_event("error", {"message": f"调用上游 API 失败: {str(e)}"})


async def _zhipu_image_stream(
    messages: List[Dict[str, str]],
    model: str,
) -> AsyncGenerator[str, None]:
    """调用智谱 CogView 文生图 API"""
    url = f"{settings.ZHIPU_BASE_URL}/images/generations"
    headers = {
        "Authorization": f"Bearer {settings.ZHIPU_API_KEY}",
        "Content-Type": "application/json",
    }

    # 从消息中提取用户 prompt
    prompt = ""
    for msg in reversed(messages):
        if msg.get("role") == "user":
            prompt = msg.get("content", "")
            break

    payload = {
        "model": model,
        "prompt": prompt,
        "size": "1024x1024",
    }

    try:
        async with httpx.AsyncClient(timeout=120.0) as client:
            response = await client.post(url, headers=headers, json=payload)
            if response.status_code != 200:
                yield _sse_event("error", {
                    "message": f"上游图片生成 API 错误 {response.status_code}: {response.text}"
                })
                return

            data = response.json()
            image_url = data.get("data", [{}])[0].get("url", "")
            if not image_url:
                yield _sse_event("error", {"message": "上游 API 未返回图片 URL"})
                return

            yield _sse_event("image", {"url": image_url, "model": model})
            yield _sse_event("done", {
                "conversation_id": None,
                "model": model,
                "tokens_used": 1024,
            })
    except httpx.TimeoutException:
        yield _sse_event("error", {"message": "上游图片生成 API 请求超时"})
    except Exception as e:
        yield _sse_event("error", {"message": f"调用上游图片生成 API 失败: {str(e)}"})


async def _zhipu_video_stream(
    messages: List[Dict[str, str]],
    model: str,
) -> AsyncGenerator[str, None]:
    """调用智谱 CogVideo 文生视频 API"""
    url = f"{settings.ZHIPU_BASE_URL}/videos/generations"
    headers = {
        "Authorization": f"Bearer {settings.ZHIPU_API_KEY}",
        "Content-Type": "application/json",
    }

    prompt = ""
    for msg in reversed(messages):
        if msg.get("role") == "user":
            prompt = msg.get("content", "")
            break

    payload = {
        "model": model,
        "prompt": prompt,
    }

    try:
        async with httpx.AsyncClient(timeout=120.0) as client:
            response = await client.post(url, headers=headers, json=payload)
            if response.status_code != 200:
                yield _sse_event("error", {
                    "message": f"上游视频生成 API 错误 {response.status_code}: {response.text}"
                })
                return

            data = response.json()
            task_id = data.get("id", "")
            video_url = data.get("video_url", "")

            if task_id:
                yield _sse_event("video_task", {"task_id": task_id, "status": "processing"})

            if video_url:
                yield _sse_event("video_task", {
                    "task_id": task_id,
                    "status": "completed",
                    "url": video_url,
                })

            yield _sse_event("done", {
                "conversation_id": None,
                "model": model,
                "tokens_used": 4096,
            })
    except httpx.TimeoutException:
        yield _sse_event("error", {"message": "上游视频生成 API 请求超时"})
    except Exception as e:
        yield _sse_event("error", {"message": f"调用上游视频生成 API 失败: {str(e)}"})


# ===== 对外主接口 =====
async def chat_stream(
    messages: List[Dict[str, str]],
    model: str = "glm-4-flash",
    web_search_results: Optional[List[Dict]] = None,
) -> AsyncGenerator[str, None]:
    """
    聊天流式生成主入口
    未配置 ZHIPU_API_KEY 时返回错误事件，绝不生成模拟回复
    """
    # 未配置上游 API Key 时返回错误
    if not settings.ZHIPU_API_KEY:
        payload = {"type": "error", "message": "未配置模型密钥，请在服务端配置 ZHIPU_API_KEY 环境变量"}
        yield f"data: {json.dumps(payload, ensure_ascii=False)}\n\n"
        return

    model_type = get_model_type(model)

    # 图片生成模型
    if model_type == "image":
        async for event in _zhipu_image_stream(messages, model):
            yield event
        return

    # 视频生成模型
    if model_type == "video":
        async for event in _zhipu_video_stream(messages, model):
            yield event
        return

    # 对话/视觉模型
    async for event in _zhipu_chat_stream(messages, model, web_search_results):
        yield event
