"""
好友/社交路由
好友列表、好友请求、接受/拒绝/删除
"""
import uuid
from datetime import datetime, timezone
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query

from auth import get_current_user
from models_extra import FriendRequest as FriendRequestModel
from database import get_db_conn, fetch_one, fetch_all, execute

router = APIRouter()


def _now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


# ===== 好友列表 =====
@router.get("/api/friends")
async def get_friends(
    page: int = Query(1, ge=1),
    page_size: int = Query(50, ge=1, le=200),
    current_user: dict = Depends(get_current_user),
):
    """获取当前用户的好友列表"""
    offset = (page - 1) * page_size
    user_id = current_user["id"]

    async with get_db_conn() as conn:
        rows = await fetch_all(
            conn,
            """SELECT f.friend_id as user_id, u.nickname, u.avatar, f.added_at
               FROM friends f
               LEFT JOIN users u ON f.friend_id = u.id
               WHERE f.user_id = ?
               ORDER BY f.added_at DESC LIMIT ? OFFSET ?""",
            (user_id, page_size, offset),
        )
        total_row = await fetch_one(
            conn,
            "SELECT COUNT(*) as cnt FROM friends WHERE user_id = ?",
            (user_id,),
        )

    return {
        "code": 0,
        "message": "success",
        "data": {
            "items": rows,
            "total": total_row["cnt"] if total_row else 0,
            "page": page,
            "page_size": page_size,
        },
    }


# ===== 发送好友请求 =====
@router.post("/api/friends/request")
async def send_friend_request(
    body: FriendRequestModel,
    current_user: dict = Depends(get_current_user),
):
    """发送好友请求"""
    from_user_id = current_user["id"]
    to_user_id = body.target_user_id

    if from_user_id == to_user_id:
        raise HTTPException(status_code=400, detail="不能添加自己为好友")

    async with get_db_conn() as conn:
        # 检查目标用户是否存在
        target = await fetch_one(
            conn, "SELECT id FROM users WHERE id = ?", (to_user_id,)
        )
        if not target:
            raise HTTPException(status_code=404, detail="目标用户不存在")

        # 检查是否已经是好友
        existing = await fetch_one(
            conn,
            "SELECT id FROM friends WHERE user_id = ? AND friend_id = ?",
            (from_user_id, to_user_id),
        )
        if existing:
            raise HTTPException(status_code=400, detail="已经是好友")

        # 检查是否已有待处理请求
        pending = await fetch_one(
            conn,
            """SELECT id FROM friend_requests
               WHERE from_user_id = ? AND to_user_id = ? AND status = 'pending'""",
            (from_user_id, to_user_id),
        )
        if pending:
            raise HTTPException(status_code=400, detail="已发送过好友请求，等待对方处理")

        # 检查对方是否也发了请求给我（自动接受）
        reverse = await fetch_one(
            conn,
            """SELECT id FROM friend_requests
               WHERE from_user_id = ? AND to_user_id = ? AND status = 'pending'""",
            (to_user_id, from_user_id),
        )

        now = _now_iso()

        if reverse:
            # 双向请求，自动成为好友
            await execute(
                conn,
                "UPDATE friend_requests SET status = 'accepted', handled_at = ? WHERE id = ?",
                (now, reverse["id"]),
            )
            await _add_friend(conn, from_user_id, to_user_id, now)
            return {"code": 0, "message": "已自动成为好友", "data": {"auto_accepted": True}}

        # 创建新请求
        request_id = uuid.uuid4().hex
        await execute(
            conn,
            """INSERT INTO friend_requests
               (id, from_user_id, to_user_id, message, status, created_at)
               VALUES (?, ?, ?, ?, 'pending', ?)""",
            (request_id, from_user_id, to_user_id, body.message, now),
        )

    return {
        "code": 0,
        "message": "好友请求已发送",
        "data": {"request_id": request_id},
    }


# ===== 收到的好友请求 =====
@router.get("/api/friends/requests")
async def get_friend_requests(
    status: str = Query("pending", description="pending/accepted/rejected"),
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    current_user: dict = Depends(get_current_user),
):
    """获取收到的好友请求列表"""
    offset = (page - 1) * page_size
    user_id = current_user["id"]

    async with get_db_conn() as conn:
        rows = await fetch_all(
            conn,
            """SELECT r.id, r.from_user_id, u.nickname as from_nickname,
                      u.avatar as from_avatar, r.message, r.status, r.created_at
               FROM friend_requests r
               LEFT JOIN users u ON r.from_user_id = u.id
               WHERE r.to_user_id = ? AND r.status = ?
               ORDER BY r.created_at DESC LIMIT ? OFFSET ?""",
            (user_id, status, page_size, offset),
        )
        total_row = await fetch_one(
            conn,
            """SELECT COUNT(*) as cnt FROM friend_requests
               WHERE to_user_id = ? AND status = ?""",
            (user_id, status),
        )

    return {
        "code": 0,
        "message": "success",
        "data": {
            "items": rows,
            "total": total_row["cnt"] if total_row else 0,
            "page": page,
            "page_size": page_size,
        },
    }


# ===== 接受好友请求 =====
@router.post("/api/friends/{request_id}/accept")
async def accept_friend_request(
    request_id: str,
    current_user: dict = Depends(get_current_user),
):
    """接受好友请求"""
    user_id = current_user["id"]
    now = _now_iso()

    async with get_db_conn() as conn:
        req = await fetch_one(
            conn,
            "SELECT * FROM friend_requests WHERE id = ? AND to_user_id = ?",
            (request_id, user_id),
        )
        if not req:
            raise HTTPException(status_code=404, detail="请求不存在")
        if req["status"] != "pending":
            raise HTTPException(status_code=400, detail="请求已处理")

        await execute(
            conn,
            "UPDATE friend_requests SET status = 'accepted', handled_at = ? WHERE id = ?",
            (now, request_id),
        )

        await _add_friend(conn, user_id, req["from_user_id"], now)

    return {"code": 0, "message": "已接受好友请求"}


# ===== 拒绝好友请求 =====
@router.post("/api/friends/{request_id}/reject")
async def reject_friend_request(
    request_id: str,
    current_user: dict = Depends(get_current_user),
):
    """拒绝好友请求"""
    user_id = current_user["id"]
    now = _now_iso()

    async with get_db_conn() as conn:
        req = await fetch_one(
            conn,
            "SELECT * FROM friend_requests WHERE id = ? AND to_user_id = ?",
            (request_id, user_id),
        )
        if not req:
            raise HTTPException(status_code=404, detail="请求不存在")
        if req["status"] != "pending":
            raise HTTPException(status_code=400, detail="请求已处理")

        await execute(
            conn,
            "UPDATE friend_requests SET status = 'rejected', handled_at = ? WHERE id = ?",
            (now, request_id),
        )

    return {"code": 0, "message": "已拒绝好友请求"}


# ===== 删除好友 =====
@router.delete("/api/friends/{friend_id}")
async def delete_friend(
    friend_id: str,
    current_user: dict = Depends(get_current_user),
):
    """删除好友（双向解除）"""
    user_id = current_user["id"]

    async with get_db_conn() as conn:
        # 检查是否是好友
        existing = await fetch_one(
            conn,
            "SELECT id FROM friends WHERE user_id = ? AND friend_id = ?",
            (user_id, friend_id),
        )
        if not existing:
            raise HTTPException(status_code=404, detail="不是好友关系")

        # 双向删除
        await execute(
            conn,
            "DELETE FROM friends WHERE (user_id = ? AND friend_id = ?) OR (user_id = ? AND friend_id = ?)",
            (user_id, friend_id, friend_id, user_id),
        )

    return {"code": 0, "message": "已删除好友"}


# ===== 内部辅助 =====
async def _add_friend(conn, user_a: str, user_b: str, now: str):
    """双向添加好友关系"""
    # A -> B
    await execute(
        conn,
        """INSERT OR IGNORE INTO friends (id, user_id, friend_id, added_at)
           VALUES (?, ?, ?, ?)""",
        (uuid.uuid4().hex, user_a, user_b, now),
    )
    # B -> A
    await execute(
        conn,
        """INSERT OR IGNORE INTO friends (id, user_id, friend_id, added_at)
           VALUES (?, ?, ?, ?)""",
        (uuid.uuid4().hex, user_b, user_a, now),
    )
