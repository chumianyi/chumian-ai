"""
通知路由 - 通知列表、标记已读
"""
import uuid
from datetime import datetime, timezone
from typing import List

from fastapi import APIRouter, Depends, HTTPException, Query
import aiosqlite

from models import NotificationResponse
from auth import get_current_user
from database import get_db, fetch_one, fetch_all, execute

router = APIRouter()


def _now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


# ===== 通知列表 =====
@router.get("/api/notifications")
async def list_notifications(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    unread_only: bool = Query(False),
    current_user: dict = Depends(get_current_user),
    db: aiosqlite.Connection = Depends(get_db),
):
    """获取当前用户的通知列表"""
    offset = (page - 1) * page_size

    query = "SELECT * FROM notifications WHERE user_id = ?"
    params = [current_user["id"]]

    if unread_only:
        query += " AND is_read = 0"

    query += " ORDER BY created_at DESC LIMIT ? OFFSET ?"
    params.extend([page_size, offset])

    rows = await fetch_all(db, query, tuple(params))

    # 统计未读数
    unread_count = await fetch_one(
        db,
        "SELECT COUNT(*) as cnt FROM notifications WHERE user_id = ? AND is_read = 0",
        (current_user["id"],),
    )

    return {
        "items": [NotificationResponse(**r) for r in rows],
        "total": len(rows),
        "page": page,
        "page_size": page_size,
        "unread_count": unread_count["cnt"] if unread_count else 0,
    }


# ===== 标记已读 =====
@router.post("/api/notifications/{nid}/read")
async def mark_notification_read(
    nid: str,
    current_user: dict = Depends(get_current_user),
    db: aiosqlite.Connection = Depends(get_db),
):
    """标记单条通知为已读"""
    notif = await fetch_one(
        db,
        "SELECT id, user_id FROM notifications WHERE id = ?",
        (nid,),
    )
    if not notif:
        raise HTTPException(status_code=404, detail="通知不存在")

    if notif["user_id"] != current_user["id"]:
        raise HTTPException(status_code=403, detail="无权操作此通知")

    await execute(
        db, "UPDATE notifications SET is_read = 1 WHERE id = ?", (nid,)
    )

    return {"message": "已标记为已读", "notification_id": nid}


# ===== 全部标记已读 =====
@router.post("/api/notifications/read-all")
async def mark_all_read(
    current_user: dict = Depends(get_current_user),
    db: aiosqlite.Connection = Depends(get_db),
):
    """将当前用户所有通知标记为已读"""
    await execute(
        db,
        "UPDATE notifications SET is_read = 1 WHERE user_id = ? AND is_read = 0",
        (current_user["id"],),
    )
    return {"message": "全部通知已标记为已读"}
