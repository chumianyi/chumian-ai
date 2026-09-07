"""
成就路由
成就列表、我的成就（进度）、领取奖励
"""
from fastapi import APIRouter, Depends, HTTPException

from auth import get_current_user
from services.achievement_service import achievement_service

router = APIRouter()


# ===== 全部成就列表 =====
@router.get("/api/achievements")
async def get_all_achievements(
    current_user: dict = Depends(get_current_user),
):
    """获取所有成就定义列表"""
    achievements = await achievement_service.get_all_achievements()
    return {"code": 0, "message": "success", "data": achievements}


# ===== 我的成就 =====
@router.get("/api/achievements/my")
async def get_my_achievements(
    current_user: dict = Depends(get_current_user),
):
    """
    获取我的成就（已解锁 + 进度）
    同时自动检测并更新进度
    """
    user_id = current_user["id"]

    # 自动检测解锁
    newly_unlocked = await achievement_service.check_and_unlock(user_id)

    # 获取完整成就状态
    achievements = await achievement_service.get_user_achievements(user_id)

    unlocked_count = sum(1 for a in achievements if a["unlocked"])
    total_count = len(achievements)

    return {
        "code": 0,
        "message": "success",
        "data": {
            "achievements": achievements,
            "unlocked_count": unlocked_count,
            "total_count": total_count,
            "newly_unlocked": newly_unlocked,
        },
    }


# ===== 领取成就奖励 =====
@router.post("/api/achievements/{achievement_id}/claim")
async def claim_achievement(
    achievement_id: str,
    current_user: dict = Depends(get_current_user),
):
    """领取成就奖励（积分/钻石）"""
    result = await achievement_service.claim_reward(
        user_id=current_user["id"],
        achievement_id=achievement_id,
    )

    if not result.get("success"):
        raise HTTPException(status_code=400, detail=result.get("error", "领取失败"))

    return {
        "code": 0,
        "message": "奖励领取成功",
        "data": result,
    }
