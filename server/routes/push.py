"""
推送路由
设备注册、推送发送（管理员）、推送设置管理
"""
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Header, Query

from auth import get_current_user
from models_extra import PushDevice, PushSettings, PushSendRequest
from services.push_service import push_service

router = APIRouter()

# 管理员 token
import os
ADMIN_TOKEN = os.getenv("ADMIN_TOKEN", "chumian-admin-2024")


async def verify_admin(x_admin_token: Optional[str] = Header(None)):
    """管理员认证"""
    if not x_admin_token or x_admin_token != ADMIN_TOKEN:
        raise HTTPException(status_code=401, detail="管理员认证失败")
    return True


# ===== 注册推送设备 =====
@router.post("/api/push/register")
async def register_device(
    body: PushDevice,
    current_user: dict = Depends(get_current_user),
):
    """
    注册推送设备
    同一设备重复注册会更新活跃时间
    """
    if body.platform not in ["android", "ios", "web"]:
        raise HTTPException(
            status_code=400,
            detail="不支持的平台，支持: android/ios/web",
        )

    result = await push_service.register_device(
        user_id=current_user["id"],
        device_token=body.device_token,
        platform=body.platform,
        device_model=body.device_model,
    )

    return {"code": 0, "message": "设备注册成功", "data": result}


# ===== 发送推送（管理员） =====
@router.post("/api/push/send")
async def send_push(
    body: PushSendRequest,
    admin: bool = Depends(verify_admin),
):
    """
    发送推送（管理员接口）
    user_id 为空时广播给所有用户
    """
    result = await push_service.send_push(
        user_id=body.user_id,
        title=body.title,
        body=body.body,
        push_type=body.push_type,
    )

    return {"code": 0, "message": "推送已发送", "data": result}


# ===== 获取推送设置 =====
@router.get("/api/push/settings")
async def get_push_settings(
    current_user: dict = Depends(get_current_user),
):
    """获取当前用户的推送设置"""
    settings = await push_service.get_settings(current_user["id"])
    return {"code": 0, "message": "success", "data": settings}


# ===== 更新推送设置 =====
@router.put("/api/push/settings")
async def update_push_settings(
    body: PushSettings,
    current_user: dict = Depends(get_current_user),
):
    """更新当前用户的推送设置"""
    settings = await push_service.update_settings(
        user_id=current_user["id"],
        enabled=body.enabled,
        message_push=body.message_push,
        system_push=body.system_push,
        marketing_push=body.marketing_push,
    )
    return {"code": 0, "message": "设置已更新", "data": settings}
