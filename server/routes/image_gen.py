"""
AI 绘画路由
风格预设：写实/动漫/油画/水彩/赛博朋克
尺寸：512x512/768x768/1024x1024
异步任务 + 轮询查询
"""
from fastapi import APIRouter, Depends, HTTPException, Query
from typing import Optional

from auth import get_current_user
from models_extra import ImageGenRequest
from services.image_gen_service import image_gen_service
from services.rate_limiter import rate_limiter

router = APIRouter()


# ===== 创建绘画任务 =====
@router.post("/api/image/generate")
async def create_image_task(
    body: ImageGenRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    创建 AI 绘画任务
    返回任务 ID，通过 GET /api/image/{task_id} 轮询结果
    """
    user_id = current_user["id"]

    # 限流：每用户每小时 10 次
    await rate_limiter.check("image", f"user:{user_id}")

    # 参数校验
    error = image_gen_service.validate_request(body.prompt, body.style, body.size)
    if error:
        raise HTTPException(status_code=400, detail=error)

    # 创建任务
    result = await image_gen_service.create_task(
        user_id=user_id,
        prompt=body.prompt,
        style=body.style,
        size=body.size,
        negative_prompt=body.negative_prompt,
    )

    return {"code": 0, "message": "任务已创建", "data": result}


# ===== 查询任务状态 =====
@router.get("/api/image/{task_id}")
async def get_image_task(
    task_id: str,
    current_user: dict = Depends(get_current_user),
):
    """查询绘画任务状态和结果"""
    task = await image_gen_service.get_task(task_id, current_user["id"])
    if not task:
        raise HTTPException(status_code=404, detail="任务不存在")

    return {"code": 0, "message": "success", "data": task}


# ===== 绘画历史 =====
@router.get("/api/image/history")
async def get_image_history(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    current_user: dict = Depends(get_current_user),
):
    """获取当前用户的绘画历史列表"""
    result = await image_gen_service.get_history(
        user_id=current_user["id"],
        page=page,
        page_size=page_size,
    )
    return {"code": 0, "message": "success", "data": result}


# ===== 删除绘画记录 =====
@router.delete("/api/image/{task_id}")
async def delete_image_task(
    task_id: str,
    current_user: dict = Depends(get_current_user),
):
    """删除绘画历史记录"""
    success = await image_gen_service.delete_task(task_id, current_user["id"])
    if not success:
        raise HTTPException(status_code=404, detail="记录不存在或无权删除")

    return {"code": 0, "message": "删除成功"}
