"""
管理员路由
平台统计、用户管理、帖子审核、系统日志
简单 admin token 认证（Header: X-Admin-Token）
"""
import uuid
from datetime import datetime, timezone
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Header, Query

from config import settings
from database import get_db, fetch_one, fetch_all, execute
from services.analytics_service import analytics_service
from services.content_moderation import content_moderation

router = APIRouter()

# 管理员 token（从环境变量读取，默认开发用固定值）
ADMIN_TOKEN = __import__("os").getenv("ADMIN_TOKEN", "chumian-admin-2024")


def _now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


async def verify_admin(
    x_admin_token: Optional[str] = Header(None),
) -> dict:
    """
    管理员认证依赖
    通过 X-Admin-Token header 验证
    """
    if not x_admin_token or x_admin_token != ADMIN_TOKEN:
        raise HTTPException(
            status_code=401,
            detail="管理员认证失败",
            headers={"WWW-Authenticate": "AdminToken"},
        )
    return {"admin_id": "admin", "authenticated": True}


async def _log_admin_action(
    admin_id: str,
    action: str,
    target_type: Optional[str] = None,
    target_id: Optional[str] = None,
    detail: Optional[str] = None,
    ip: Optional[str] = None,
):
    """记录管理员操作日志"""
    log_id = uuid.uuid4().hex
    import aiosqlite
    from database import get_db_conn
    async with get_db_conn() as conn:
        await execute(
            conn,
            """INSERT INTO admin_logs
               (id, admin_id, action, target_type, target_id, detail, ip, created_at)
               VALUES (?, ?, ?, ?, ?, ?, ?, ?)""",
            (log_id, admin_id, action, target_type, target_id, detail, ip, _now_iso()),
        )


# ===== 平台统计 =====
@router.get("/api/admin/stats")
async def admin_stats(
    admin: dict = Depends(verify_admin),
):
    """获取平台统计数据"""
    stats = await analytics_service.get_platform_stats()
    return {"code": 0, "message": "success", "data": stats}


# ===== 用户列表 =====
@router.get("/api/admin/users")
async def admin_user_list(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    search: Optional[str] = Query(None, description="按邮箱/昵称搜索"),
    banned: Optional[int] = Query(None, description="1=仅封禁, 0=仅正常"),
    admin: dict = Depends(verify_admin),
):
    """获取用户列表（分页/搜索/筛选）"""
    offset = (page - 1) * page_size
    conditions = []
    params = []

    if search:
        conditions.append("(email LIKE ? OR nickname LIKE ?)")
        params.extend([f"%{search}%", f"%{search}%"])
    if banned is not None:
        conditions.append("is_banned = ?")
        params.append(banned)

    where = " AND ".join(conditions) if conditions else "1=1"

    import aiosqlite
    from database import get_db_conn
    async with get_db_conn() as conn:
        rows = await fetch_all(
            conn,
            f"""SELECT id, email, nickname, is_banned, ban_until, daily_points,
                       vip_status, created_at
                FROM users WHERE {where}
                ORDER BY created_at DESC LIMIT ? OFFSET ?""",
            tuple(params + [page_size, offset]),
        )
        total_row = await fetch_one(
            conn, f"SELECT COUNT(*) as cnt FROM users WHERE {where}", tuple(params)
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


# ===== 封禁用户 =====
@router.post("/api/admin/users/{user_id}/ban")
async def ban_user(
    user_id: str,
    ban_days: int = Query(0, ge=0, description="封禁天数，0=永久"),
    reason: Optional[str] = Query(None),
    admin: dict = Depends(verify_admin),
):
    """封禁用户"""
    import aiosqlite
    from database import get_db_conn
    async with get_db_conn() as conn:
        user = await fetch_one(conn, "SELECT id FROM users WHERE id = ?", (user_id,))
        if not user:
            raise HTTPException(status_code=404, detail="用户不存在")

        if ban_days > 0:
            ban_until = (
                datetime.now(timezone.utc).timestamp() + ban_days * 86400
            )
            ban_until_iso = datetime.fromtimestamp(
                ban_until, tz=timezone.utc
            ).isoformat()
        else:
            ban_until_iso = None

        await execute(
            conn,
            "UPDATE users SET is_banned = 1, ban_until = ? WHERE id = ?",
            (ban_until_iso, user_id),
        )

    await _log_admin_action(
        admin["admin_id"], "ban_user", "user", user_id,
        f"封禁{'永久' if ban_days == 0 else f'{ban_days}天'}: {reason or ''}",
    )

    return {"code": 0, "message": "用户已封禁"}


# ===== 解封用户 =====
@router.post("/api/admin/users/{user_id}/unban")
async def unban_user(
    user_id: str,
    admin: dict = Depends(verify_admin),
):
    """解封用户"""
    import aiosqlite
    from database import get_db_conn
    async with get_db_conn() as conn:
        user = await fetch_one(conn, "SELECT id FROM users WHERE id = ?", (user_id,))
        if not user:
            raise HTTPException(status_code=404, detail="用户不存在")

        await execute(
            conn,
            "UPDATE users SET is_banned = 0, ban_until = NULL WHERE id = ?",
            (user_id,),
        )

    await _log_admin_action(admin["admin_id"], "unban_user", "user", user_id)
    return {"code": 0, "message": "用户已解封"}


# ===== 帖子审核列表 =====
@router.get("/api/admin/posts")
async def admin_posts(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    status: Optional[str] = Query("pending", description="pending/approved/rejected"),
    admin: dict = Depends(verify_admin),
):
    """获取待审核帖子列表"""
    offset = (page - 1) * page_size

    import aiosqlite
    from database import get_db_conn
    async with get_db_conn() as conn:
        conditions = []
        params = []
        if status == "pending":
            conditions.append("approved = 0")
        elif status == "approved":
            conditions.append("approved = 1")
        elif status == "rejected":
            conditions.append("approved = 2")

        where = " AND ".join(conditions) if conditions else "1=1"

        rows = await fetch_all(
            conn,
            f"""SELECT p.*, u.nickname, u.avatar as user_avatar
                FROM posts p
                LEFT JOIN users u ON p.user_id = u.id
                WHERE {where}
                ORDER BY p.created_at DESC LIMIT ? OFFSET ?""",
            tuple(params + [page_size, offset]),
        )
        total_row = await fetch_one(
            conn, f"SELECT COUNT(*) as cnt FROM posts p WHERE {where}", tuple(params)
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


# ===== 审核通过 =====
@router.post("/api/admin/posts/{post_id}/approve")
async def approve_post(
    post_id: str,
    admin: dict = Depends(verify_admin),
):
    """审核通过帖子"""
    import aiosqlite
    from database import get_db_conn
    async with get_db_conn() as conn:
        post = await fetch_one(conn, "SELECT id FROM posts WHERE id = ?", (post_id,))
        if not post:
            raise HTTPException(status_code=404, detail="帖子不存在")

        await execute(
            conn,
            "UPDATE posts SET approved = 1, review_status = 'approved' WHERE id = ?",
            (post_id,),
        )

    await _log_admin_action(admin["admin_id"], "approve_post", "post", post_id)
    return {"code": 0, "message": "帖子已通过审核"}


# ===== 审核拒绝 =====
@router.post("/api/admin/posts/{post_id}/reject")
async def reject_post(
    post_id: str,
    reason: Optional[str] = Query(None),
    admin: dict = Depends(verify_admin),
):
    """审核拒绝帖子"""
    import aiosqlite
    from database import get_db_conn
    async with get_db_conn() as conn:
        post = await fetch_one(conn, "SELECT id FROM posts WHERE id = ?", (post_id,))
        if not post:
            raise HTTPException(status_code=404, detail="帖子不存在")

        await execute(
            conn,
            """UPDATE posts SET approved = 2, review_status = 'rejected',
               review_note = ? WHERE id = ?""",
            (reason, post_id),
        )

    await _log_admin_action(
        admin["admin_id"], "reject_post", "post", post_id, reason
    )
    return {"code": 0, "message": "帖子已拒绝"}


# ===== 系统日志 =====
@router.get("/api/admin/logs")
async def admin_logs(
    page: int = Query(1, ge=1),
    page_size: int = Query(50, ge=1, le=200),
    action: Optional[str] = Query(None),
    admin: dict = Depends(verify_admin),
):
    """获取系统操作日志"""
    offset = (page - 1) * page_size

    import aiosqlite
    from database import get_db_conn
    async with get_db_conn() as conn:
        conditions = []
        params = []
        if action:
            conditions.append("action = ?")
            params.append(action)

        where = " AND ".join(conditions) if conditions else "1=1"

        rows = await fetch_all(
            conn,
            f"""SELECT * FROM admin_logs WHERE {where}
                ORDER BY created_at DESC LIMIT ? OFFSET ?""",
            tuple(params + [page_size, offset]),
        )
        total_row = await fetch_one(
            conn, f"SELECT COUNT(*) as cnt FROM admin_logs WHERE {where}", tuple(params)
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
