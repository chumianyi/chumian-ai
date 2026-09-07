"""
用户路由 - 用户信息、积分明细、资料更新、关注系统
"""
import uuid
from datetime import datetime, timezone
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException
import aiosqlite

from models import UserResponse, UserUpdate
from auth import get_current_user, get_optional_user
from database import get_db, fetch_one, fetch_all, execute

router = APIRouter()


def _now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def _user_to_response(user: dict) -> UserResponse:
    """将数据库用户行转换为 UserResponse"""
    return UserResponse(
        id=user["id"],
        email=user.get("email"),
        nickname=user.get("nickname"),
        avatar=user.get("avatar"),
        daily_points=user.get("daily_points", 0),
        vip_status=user.get("vip_status", 0),
        oobe_completed=user.get("oobe_completed", 0),
        is_banned=user.get("is_banned", 0),
        created_at=user.get("created_at"),
    )


# ===== 当前用户信息 =====
@router.get("/api/user/info", response_model=UserResponse)
async def get_user_info(
    current_user: dict = Depends(get_current_user),
    db: aiosqlite.Connection = Depends(get_db),
):
    """获取当前登录用户的完整信息"""
    # 重新查询以获取最新数据
    user = await fetch_one(db, "SELECT * FROM users WHERE id = ?", (current_user["id"],))
    if not user:
        raise HTTPException(status_code=404, detail="用户不存在")
    return _user_to_response(user)


# ===== 积分明细 =====
@router.get("/api/user/points-log")
async def get_points_log(
    page: int = 1,
    page_size: int = 20,
    current_user: dict = Depends(get_current_user),
    db: aiosqlite.Connection = Depends(get_db),
):
    """获取当前用户的积分变动明细（分页）"""
    offset = (page - 1) * page_size

    rows = await fetch_all(
        db,
        """SELECT * FROM points_log WHERE user_id = ?
           ORDER BY created_at DESC LIMIT ? OFFSET ?""",
        (current_user["id"], page_size, offset),
    )

    total = await fetch_one(
        db, "SELECT COUNT(*) as cnt FROM points_log WHERE user_id = ?",
        (current_user["id"],),
    )

    return {
        "items": rows,
        "total": total["cnt"] if total else 0,
        "page": page,
        "page_size": page_size,
    }


# ===== 更新资料 =====
@router.put("/api/profile", response_model=UserResponse)
async def update_profile(
    body: UserUpdate,
    current_user: dict = Depends(get_current_user),
    db: aiosqlite.Connection = Depends(get_db),
):
    """更新当前用户资料（nickname/avatar/qq/birthday）"""
    updates = []
    params = []

    if body.nickname is not None:
        updates.append("nickname = ?")
        params.append(body.nickname)
    if body.avatar is not None:
        updates.append("avatar = ?")
        params.append(body.avatar)
    if body.qq is not None:
        updates.append("qq = ?")
        params.append(body.qq)
    if body.birthday is not None:
        updates.append("birthday = ?")
        params.append(body.birthday)

    if not updates:
        return _user_to_response(current_user)

    params.append(current_user["id"])
    await execute(
        db, f"UPDATE users SET {', '.join(updates)} WHERE id = ?", tuple(params)
    )

    # 返回更新后的用户信息
    user = await fetch_one(db, "SELECT * FROM users WHERE id = ?", (current_user["id"],))
    return _user_to_response(user)


# ===== 用户公开资料 =====
@router.get("/api/users/{user_id}")
async def get_user_profile(
    user_id: str,
    current_user: Optional[dict] = Depends(get_optional_user),
    db: aiosqlite.Connection = Depends(get_db),
):
    """获取指定用户的公开资料"""
    user = await fetch_one(db, "SELECT * FROM users WHERE id = ?", (user_id,))
    if not user:
        raise HTTPException(status_code=404, detail="用户不存在")

    # 统计粉丝数和关注数
    followers_count = await fetch_one(
        db, "SELECT COUNT(*) as cnt FROM follows WHERE following_id = ?", (user_id,)
    )
    following_count = await fetch_one(
        db, "SELECT COUNT(*) as cnt FROM follows WHERE follower_id = ?", (user_id,)
    )

    # 统计帖子数
    posts_count = await fetch_one(
        db, "SELECT COUNT(*) as cnt FROM posts WHERE user_id = ? AND approved = 1",
        (user_id,),
    )

    # 当前用户是否已关注
    is_following = False
    if current_user:
        follow = await fetch_one(
            db,
            "SELECT id FROM follows WHERE follower_id = ? AND following_id = ?",
            (current_user["id"], user_id),
        )
        is_following = follow is not None

    return {
        "id": user["id"],
        "nickname": user.get("nickname"),
        "avatar": user.get("avatar"),
        "vip_status": user.get("vip_status", 0),
        "bio": user.get("qq", ""),  # 用 qq 字段作为简介展示
        "followers_count": followers_count["cnt"] if followers_count else 0,
        "following_count": following_count["cnt"] if following_count else 0,
        "posts_count": posts_count["cnt"] if posts_count else 0,
        "is_following": is_following,
        "created_at": user.get("created_at"),
    }


# ===== 关注/取消关注 =====
@router.post("/api/users/{user_id}/follow")
async def follow_user(
    user_id: str,
    current_user: dict = Depends(get_current_user),
    db: aiosqlite.Connection = Depends(get_db),
):
    """关注或取消关注用户（切换）"""
    if user_id == current_user["id"]:
        raise HTTPException(status_code=400, detail="不能关注自己")

    # 检查目标用户是否存在
    target = await fetch_one(db, "SELECT id FROM users WHERE id = ?", (user_id,))
    if not target:
        raise HTTPException(status_code=404, detail="用户不存在")

    # 检查是否已关注
    existing = await fetch_one(
        db,
        "SELECT id FROM follows WHERE follower_id = ? AND following_id = ?",
        (current_user["id"], user_id),
    )

    if existing:
        # 取消关注
        await execute(
            db, "DELETE FROM follows WHERE id = ?", (existing["id"],)
        )
        return {"message": "已取消关注", "is_following": False}
    else:
        # 关注
        follow_id = uuid.uuid4().hex
        await execute(
            db,
            "INSERT INTO follows (id, follower_id, following_id, created_at) VALUES (?, ?, ?, ?)",
            (follow_id, current_user["id"], user_id, _now_iso()),
        )

        # 发送通知
        notif_id = uuid.uuid4().hex
        await execute(
            db,
            """INSERT INTO notifications (id, user_id, type, title, content, is_read, created_at)
               VALUES (?, ?, 'follow', '新的关注者', ?, 0, ?)""",
            (notif_id, user_id, f"{current_user.get('nickname', '有人')} 关注了你", _now_iso()),
        )

        return {"message": "关注成功", "is_following": True}


# ===== 粉丝列表 =====
@router.get("/api/users/{user_id}/followers")
async def get_followers(
    user_id: str,
    page: int = 1,
    page_size: int = 20,
    db: aiosqlite.Connection = Depends(get_db),
):
    """获取用户的粉丝列表"""
    offset = (page - 1) * page_size

    rows = await fetch_all(
        db,
        """SELECT u.id, u.nickname, u.avatar, u.vip_status
           FROM follows f
           JOIN users u ON f.follower_id = u.id
           WHERE f.following_id = ?
           ORDER BY f.created_at DESC LIMIT ? OFFSET ?""",
        (user_id, page_size, offset),
    )

    return {"items": rows, "page": page, "page_size": page_size}


# ===== 关注列表 =====
@router.get("/api/users/{user_id}/following")
async def get_following(
    user_id: str,
    page: int = 1,
    page_size: int = 20,
    db: aiosqlite.Connection = Depends(get_db),
):
    """获取用户的关注列表"""
    offset = (page - 1) * page_size

    rows = await fetch_all(
        db,
        """SELECT u.id, u.nickname, u.avatar, u.vip_status
           FROM follows f
           JOIN users u ON f.following_id = u.id
           WHERE f.follower_id = ?
           ORDER BY f.created_at DESC LIMIT ? OFFSET ?""",
        (user_id, page_size, offset),
    )

    return {"items": rows, "page": page, "page_size": page_size}
