"""
数据分析路由
事件上报、用户统计、趋势数据
"""
from fastapi import APIRouter, Depends, Request, Query
from typing import Optional

from auth import get_current_user, get_optional_user
from models_extra import AnalyticsEvent, AnalyticsBatchRequest
from services.analytics_service import analytics_service

router = APIRouter()


def _get_client_ip(request: Request) -> str:
    """提取客户端 IP"""
    forwarded = request.headers.get("x-forwarded-for")
    if forwarded:
        return forwarded.split(",")[0].strip()
    return request.client.host if request.client else "unknown"


# ===== 上报单个事件 =====
@router.post("/api/analytics/event")
async def track_event(
    body: AnalyticsEvent,
    request: Request,
    current_user: Optional[dict] = Depends(get_optional_user),
):
    """
    上报单个分析事件
    支持匿名上报（无 token 时 user_id 为 None）
    """
    user_id = current_user["id"] if current_user else None
    ip = _get_client_ip(request)
    user_agent = request.headers.get("user-agent", "")

    event_id = await analytics_service.track_event(
        user_id=user_id,
        event_type=body.event_type,
        event_name=body.event_name,
        properties=body.properties,
        ip=ip,
        user_agent=user_agent,
    )

    return {"code": 0, "message": "事件已记录", "data": {"event_id": event_id}}


# ===== 批量上报 =====
@router.post("/api/analytics/batch")
async def track_events_batch(
    body: AnalyticsBatchRequest,
    request: Request,
    current_user: Optional[dict] = Depends(get_optional_user),
):
    """批量上报分析事件"""
    user_id = current_user["id"] if current_user else None
    ip = _get_client_ip(request)
    user_agent = request.headers.get("user-agent", "")

    events_data = [evt.model_dump() for evt in body.events]
    count = await analytics_service.track_events_batch(
        user_id=user_id,
        events=events_data,
        ip=ip,
        user_agent=user_agent,
    )

    return {"code": 0, "message": f"已记录 {count} 个事件", "data": {"count": count}}


# ===== 用户使用统计 =====
@router.get("/api/analytics/summary")
async def get_user_summary(
    current_user: dict = Depends(get_current_user),
):
    """
    获取当前用户使用统计
    包含：对话数/消息数/积分消耗/活跃天数/写作数/绘画数
    """
    summary = await analytics_service.get_user_summary(current_user["id"])
    return {"code": 0, "message": "success", "data": summary}


# ===== 趋势数据 =====
@router.get("/api/analytics/trends")
async def get_trends(
    days: int = Query(7, ge=1, le=90, description="天数：7/30"),
    current_user: dict = Depends(get_current_user),
):
    """
    获取趋势数据
    返回最近 N 天每天的对话数/消息数/积分消耗
    """
    trends = await analytics_service.get_trends(
        user_id=current_user["id"],
        days=days,
    )
    return {"code": 0, "message": "success", "data": trends}
