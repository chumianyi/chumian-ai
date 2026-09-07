"""
音乐路由
支持：
- POST /api/music/generate — AI 音乐生成
- GET  /api/music/{task_id} — 查询任务状态
- GET  /api/music/history — 生成历史
- GET  /api/music/styles — 可用风格列表
- GET  /api/music/moods — 可用情绪列表
"""
from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel, Field
from typing import Optional

from auth import get_current_user
from services.music_service import music_service

router = APIRouter()


# ===== 请求模型 =====
class MusicGenerateRequest(BaseModel):
    style: str = Field("pop", description="音乐风格")
    mood: str = Field("happy", description="情绪类型")
    bpm: Optional[int] = Field(None, ge=40, le=240, description="BPM (40-240)")
    duration: int = Field(30, ge=5, le=300, description="时长（秒）")
    title: Optional[str] = Field(None, max_length=100, description="音乐标题")


# ===== 创建音乐生成任务 =====
@router.post("/api/music/generate")
async def generate_music(
    body: MusicGenerateRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    创建 AI 音乐生成任务
    异步生成，通过 GET /api/music/{task_id} 轮询结果
    """
    try:
        result = await music_service.create_task(
            user_id=current_user["id"],
            style=body.style,
            mood=body.mood,
            bpm=body.bpm,
            duration=body.duration,
            title=body.title,
        )
        return {"code": 0, "message": "音乐生成任务已创建", "data": result}
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except RuntimeError as e:
        raise HTTPException(status_code=503, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"创建任务失败: {e}")


# ===== 查询任务状态 =====
@router.get("/api/music/{task_id}")
async def get_music_task(
    task_id: str,
    current_user: dict = Depends(get_current_user),
):
    """查询音乐生成任务状态和结果"""
    task = await music_service.get_task(task_id, current_user["id"])
    if not task:
        raise HTTPException(status_code=404, detail="任务不存在")

    return {"code": 0, "message": "success", "data": task}


# ===== 生成历史 =====
@router.get("/api/music/history")
async def get_music_history(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    style: Optional[str] = Query(None, description="按风格筛选"),
    current_user: dict = Depends(get_current_user),
):
    """获取当前用户的音乐生成历史"""
    result = await music_service.get_history(
        user_id=current_user["id"],
        page=page,
        page_size=page_size,
        style=style,
    )
    return {"code": 0, "message": "success", "data": result}


# ===== 可用风格列表 =====
@router.get("/api/music/styles")
async def get_styles(
    current_user: dict = Depends(get_current_user),
):
    """获取所有可用音乐风格"""
    styles = music_service.get_styles()
    return {
        "code": 0,
        "message": "success",
        "data": {"styles": styles, "total": len(styles)},
    }


# ===== 可用情绪列表 =====
@router.get("/api/music/moods")
async def get_moods(
    current_user: dict = Depends(get_current_user),
):
    """获取所有可用情绪类型"""
    moods = music_service.get_moods()
    return {
        "code": 0,
        "message": "success",
        "data": {"moods": moods, "total": len(moods)},
    }
