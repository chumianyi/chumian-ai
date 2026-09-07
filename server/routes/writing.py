"""
AI 写作路由
支持类型：作文/论文/小说/文案/诗歌/总结/翻译
异步任务 + 轮询查询
"""
from fastapi import APIRouter, Depends, HTTPException, Query, Request
from typing import Optional

from auth import get_current_user
from models_extra import WritingRequest, WritingResponse
from services.writing_service import writing_service
from services.rate_limiter import rate_limiter

router = APIRouter()


# ===== 创建写作任务 =====
@router.post("/api/writing/generate")
async def create_writing_task(
    body: WritingRequest,
    request: Request,
    current_user: dict = Depends(get_current_user),
):
    """
    创建 AI 写作任务
    返回任务 ID，通过 GET /api/writing/{task_id} 轮询结果
    """
    user_id = current_user["id"]

    # 限流：每用户每小时 20 次
    await rate_limiter.check("writing", f"user:{user_id}")

    # 参数校验
    error = writing_service.validate_request(body.writing_type, body.topic)
    if error:
        raise HTTPException(status_code=400, detail=error)

    # 创建任务
    result = await writing_service.create_task(
        user_id=user_id,
        writing_type=body.writing_type,
        topic=body.topic,
        params=body.params,
    )

    return {"code": 0, "message": "任务已创建", "data": result}


# ===== 查询任务状态 =====
@router.get("/api/writing/{task_id}")
async def get_writing_task(
    task_id: str,
    current_user: dict = Depends(get_current_user),
):
    """查询写作任务状态和结果"""
    task = await writing_service.get_task(task_id, current_user["id"])
    if not task:
        raise HTTPException(status_code=404, detail="任务不存在")

    return {"code": 0, "message": "success", "data": task}


# ===== 写作历史 =====
@router.get("/api/writing/history")
async def get_writing_history(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    writing_type: Optional[str] = Query(None),
    current_user: dict = Depends(get_current_user),
):
    """获取当前用户的写作历史列表"""
    result = await writing_service.get_history(
        user_id=current_user["id"],
        page=page,
        page_size=page_size,
        writing_type=writing_type,
    )
    return {"code": 0, "message": "success", "data": result}


# ===== 删除写作历史 =====
@router.delete("/api/writing/{task_id}")
async def delete_writing_task(
    task_id: str,
    current_user: dict = Depends(get_current_user),
):
    """删除写作历史记录"""
    success = await writing_service.delete_task(task_id, current_user["id"])
    if not success:
        raise HTTPException(status_code=404, detail="记录不存在或无权删除")

    return {"code": 0, "message": "删除成功"}
