"""
社区路由 - 帖子列表/详情/创建/点赞/评论/探索
"""
import uuid
from datetime import datetime, timezone
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query
import aiosqlite

from models import PostCreate, PostResponse, CommentCreate, CommentResponse
from auth import get_current_user, get_optional_user
from database import get_db, fetch_one, fetch_all, execute

router = APIRouter()


def _now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


async def _enrich_post(db: aiosqlite.Connection, post: dict, current_user_id: Optional[str] = None) -> dict:
    """补充帖子的作者信息和点赞状态"""
    # 获取作者信息
    author = await fetch_one(
        db, "SELECT nickname, avatar FROM users WHERE id = ?", (post["user_id"],)
    )
    if author:
        post["nickname"] = author["nickname"]
        post["avatar"] = author["avatar"]

    # 当前用户是否已点赞
    post["is_liked"] = False
    if current_user_id:
        liked = await fetch_one(
            db,
            "SELECT id FROM post_likes WHERE post_id = ? AND user_id = ?",
            (post["id"], current_user_id),
        )
        post["is_liked"] = liked is not None

    return post


# ===== 帖子列表 =====
@router.get("/api/posts")
async def list_posts(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    post_type: Optional[str] = Query(None, alias="type"),
    current_user: Optional[dict] = Depends(get_optional_user),
    db: aiosqlite.Connection = Depends(get_db),
):
    """
    获取帖子列表（分页）
    只返回已审核通过的帖子
    """
    offset = (page - 1) * page_size

    query = "SELECT * FROM posts WHERE approved = 1"
    params = []

    if post_type:
        query += " AND type = ?"
        params.append(post_type)

    query += " ORDER BY created_at DESC LIMIT ? OFFSET ?"
    params.extend([page_size, offset])

    rows = await fetch_all(db, query, tuple(params))

    # 补充作者信息
    enriched = []
    for post in rows:
        p = await _enrich_post(db, post, current_user["id"] if current_user else None)
        enriched.append(p)

    total = await fetch_one(
        db, "SELECT COUNT(*) as cnt FROM posts WHERE approved = 1"
    )

    return {
        "items": enriched,
        "total": total["cnt"] if total else 0,
        "page": page,
        "page_size": page_size,
    }


# ===== 帖子详情 =====
@router.get("/api/posts/{post_id}", response_model=PostResponse)
async def get_post(
    post_id: str,
    current_user: Optional[dict] = Depends(get_optional_user),
    db: aiosqlite.Connection = Depends(get_db),
):
    """获取帖子详情"""
    post = await fetch_one(db, "SELECT * FROM posts WHERE id = ?", (post_id,))
    if not post:
        raise HTTPException(status_code=404, detail="帖子不存在")

    post = await _enrich_post(db, post, current_user["id"] if current_user else None)
    return PostResponse(**post)


# ===== 创建帖子 =====
@router.post("/api/posts", response_model=PostResponse)
async def create_post(
    body: PostCreate,
    current_user: dict = Depends(get_current_user),
    db: aiosqlite.Connection = Depends(get_db),
):
    """
    创建帖子
    新帖子默认 approved=0（待审核），开发环境可设为自动通过
    """
    post_id = uuid.uuid4().hex
    created_at = _now_iso()

    await execute(
        db,
        """INSERT INTO posts (id, user_id, title, content, type, media_url, agent_id,
           likes, comments_count, approved, created_at)
           VALUES (?, ?, ?, ?, ?, ?, ?, 0, 0, 1, ?)""",
        (post_id, current_user["id"], body.title, body.content,
         body.type or "text", body.media_url, body.agent_id, created_at),
    )

    post = await fetch_one(db, "SELECT * FROM posts WHERE id = ?", (post_id,))
    post = await _enrich_post(db, post, current_user["id"])
    return PostResponse(**post)


# ===== 点赞/取消点赞 =====
@router.post("/api/posts/{post_id}/like")
async def like_post(
    post_id: str,
    current_user: dict = Depends(get_current_user),
    db: aiosqlite.Connection = Depends(get_db),
):
    """点赞或取消点赞（切换）"""
    post = await fetch_one(db, "SELECT id, likes, user_id FROM posts WHERE id = ?", (post_id,))
    if not post:
        raise HTTPException(status_code=404, detail="帖子不存在")

    # 检查是否已点赞
    existing = await fetch_one(
        db,
        "SELECT id FROM post_likes WHERE post_id = ? AND user_id = ?",
        (post_id, current_user["id"]),
    )

    if existing:
        # 取消点赞
        await execute(db, "DELETE FROM post_likes WHERE id = ?", (existing["id"],))
        new_likes = max(0, post["likes"] - 1)
        await execute(db, "UPDATE posts SET likes = ? WHERE id = ?", (new_likes, post_id))
        return {"message": "已取消点赞", "likes": new_likes, "is_liked": False}
    else:
        # 点赞
        like_id = uuid.uuid4().hex
        await execute(
            db,
            "INSERT INTO post_likes (id, post_id, user_id, created_at) VALUES (?, ?, ?, ?)",
            (like_id, post_id, current_user["id"], _now_iso()),
        )
        new_likes = post["likes"] + 1
        await execute(db, "UPDATE posts SET likes = ? WHERE id = ?", (new_likes, post_id))

        # 通知帖子作者
        if post["user_id"] != current_user["id"]:
            notif_id = uuid.uuid4().hex
            await execute(
                db,
                """INSERT INTO notifications (id, user_id, type, title, content, is_read, created_at)
                   VALUES (?, ?, 'like', '帖子获赞', ?, 0, ?)""",
                (notif_id, post["user_id"],
                 f"{current_user.get('nickname', '有人')} 赞了你的帖子", _now_iso()),
            )

        return {"message": "点赞成功", "likes": new_likes, "is_liked": True}


# ===== 评论列表 =====
@router.get("/api/posts/{post_id}/comments", response_model=List[CommentResponse])
async def list_comments(
    post_id: str,
    page: int = Query(1, ge=1),
    page_size: int = Query(50, ge=1, le=200),
    db: aiosqlite.Connection = Depends(get_db),
):
    """获取帖子的评论列表"""
    offset = (page - 1) * page_size

    rows = await fetch_all(
        db,
        """SELECT c.*, u.nickname, u.avatar
           FROM comments c
           LEFT JOIN users u ON c.user_id = u.id
           WHERE c.post_id = ?
           ORDER BY c.created_at ASC LIMIT ? OFFSET ?""",
        (post_id, page_size, offset),
    )

    return [CommentResponse(**r) for r in rows]


# ===== 发表评论 =====
@router.post("/api/posts/{post_id}/comments", response_model=CommentResponse)
async def create_comment(
    post_id: str,
    body: CommentCreate,
    current_user: dict = Depends(get_current_user),
    db: aiosqlite.Connection = Depends(get_db),
):
    """发表评论"""
    post = await fetch_one(db, "SELECT id, comments_count, user_id FROM posts WHERE id = ?", (post_id,))
    if not post:
        raise HTTPException(status_code=404, detail="帖子不存在")

    comment_id = uuid.uuid4().hex
    created_at = _now_iso()

    await execute(
        db,
        "INSERT INTO comments (id, post_id, user_id, content, created_at) VALUES (?, ?, ?, ?, ?)",
        (comment_id, post_id, current_user["id"], body.content, created_at),
    )

    # 更新帖子评论数
    await execute(
        db, "UPDATE posts SET comments_count = ? WHERE id = ?",
        (post["comments_count"] + 1, post_id),
    )

    # 通知帖子作者
    if post["user_id"] != current_user["id"]:
        notif_id = uuid.uuid4().hex
        await execute(
            db,
            """INSERT INTO notifications (id, user_id, type, title, content, is_read, created_at)
               VALUES (?, ?, 'comment', '新评论', ?, 0, ?)""",
            (notif_id, post["user_id"],
             f"{current_user.get('nickname', '有人')} 评论了你的帖子", _now_iso()),
        )

    comment = await fetch_one(
        db,
        """SELECT c.*, u.nickname, u.avatar
           FROM comments c LEFT JOIN users u ON c.user_id = u.id
           WHERE c.id = ?""",
        (comment_id,),
    )
    return CommentResponse(**comment)


# ===== 探索 =====
@router.get("/api/explore")
async def explore(
    post_type: Optional[str] = Query(None, alias="type"),
    sort: str = Query("hot", regex="^(hot|new)$"),
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    current_user: Optional[dict] = Depends(get_optional_user),
    db: aiosqlite.Connection = Depends(get_db),
):
    """
    探索页面：按类型筛选，按热度或时间排序
    """
    offset = (page - 1) * page_size

    query = "SELECT * FROM posts WHERE approved = 1"
    params = []

    if post_type:
        query += " AND type = ?"
        params.append(post_type)

    if sort == "hot":
        query += " ORDER BY (likes * 3 + comments_count * 2) DESC, created_at DESC"
    else:
        query += " ORDER BY created_at DESC"

    query += " LIMIT ? OFFSET ?"
    params.extend([page_size, offset])

    rows = await fetch_all(db, query, tuple(params))

    enriched = []
    for post in rows:
        p = await _enrich_post(db, post, current_user["id"] if current_user else None)
        enriched.append(p)

    return {"items": enriched, "page": page, "page_size": page_size, "sort": sort}
