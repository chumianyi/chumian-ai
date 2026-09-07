"""
导出路由
支持：
- POST /api/export/chat — 导出聊天记录
- GET  /api/export/{task_id} — 查询导出状态
- GET  /api/export/download/{file_id} — 下载导出文件
- GET  /api/export/history — 导出历史
"""
import os
from fastapi import APIRouter, Depends, HTTPException, Query
from fastapi.responses import FileResponse
from pydantic import BaseModel, Field
from typing import Optional

from auth import get_current_user
from services.export_service import export_service

router = APIRouter()


# ===== 请求模型 =====
class ExportChatRequest(BaseModel):
    conversation_id: str = Field(..., description="会话ID")
    format: str = Field("md", description="导出格式: txt/md/json")
    include_metadata: bool = Field(True, description="是否包含元数据（模型、Token等）")


# ===== 创建导出任务 =====
@router.post("/api/export/chat")
async def export_chat(
    body: ExportChatRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    导出聊天记录
    异步生成导出文件，通过 GET /api/export/{task_id} 轮询状态
    """
    try:
        result = await export_service.create_export(
            user_id=current_user["id"],
            conversation_id=body.conversation_id,
            export_format=body.format,
            include_metadata=body.include_metadata,
        )
        return {"code": 0, "message": "导出任务已创建", "data": result}
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"创建导出任务失败: {e}")


# ===== 查询导出状态 =====
@router.get("/api/export/{task_id}")
async def get_export_status(
    task_id: str,
    current_user: dict = Depends(get_current_user),
):
    """查询导出任务状态"""
    task = await export_service.get_task(task_id, current_user["id"])
    if not task:
        raise HTTPException(status_code=404, detail="导出任务不存在")

    return {"code": 0, "message": "success", "data": task}


# ===== 下载导出文件 =====
@router.get("/api/export/download/{file_id}")
async def download_export(
    file_id: str,
    current_user: dict = Depends(get_current_user),
):
    """
    下载导出文件
    文件在生成后 24 小时内有效
    """
    file_info = await export_service.get_download_file(file_id, current_user["id"])

    if not file_info:
        raise HTTPException(status_code=404, detail="文件不存在或已过期")

    if file_info.get("expired"):
        raise HTTPException(status_code=410, detail="文件已过期，请重新导出")

    filepath = file_info["file_path"]
    filename = file_info["filename"]
    fmt = file_info["format"]

    # 设置 MIME 类型
    mime_types = {
        "txt": "text/plain",
        "md": "text/markdown",
        "json": "application/json",
    }
    media_type = mime_types.get(fmt, "application/octet-stream")

    return FileResponse(
        path=filepath,
        filename=filename,
        media_type=media_type,
    )


# ===== 导出历史 =====
@router.get("/api/export/history")
async def get_export_history(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    current_user: dict = Depends(get_current_user),
):
    """获取导出历史列表"""
    result = await export_service.get_history(
        user_id=current_user["id"],
        page=page,
        page_size=page_size,
    )
    return {"code": 0, "message": "success", "data": result}


# ===== 支持的格式列表 =====
@router.get("/api/export/formats")
async def get_supported_formats(
    current_user: dict = Depends(get_current_user),
):
    """获取支持的导出格式"""
    formats = [
        {"id": "txt", "name": "纯文本", "extension": ".txt", "mime": "text/plain"},
        {"id": "md", "name": "Markdown", "extension": ".md", "mime": "text/markdown"},
        {"id": "json", "name": "JSON", "extension": ".json", "mime": "application/json"},
    ]
    return {
        "code": 0,
        "message": "success",
        "data": {"formats": formats, "total": len(formats)},
    }
