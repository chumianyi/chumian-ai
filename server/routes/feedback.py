"""
反馈路由
用户提交反馈、查看反馈列表和详情（含管理员回复）
"""
import uuid
from datetime import datetime, timezone
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query

from auth import get_current_user
from models_extra import FeedbackRequest
from database import get_db_conn, fetch_one, fetch_all, execute

router = APIRouter()

VALID_FEEDBACK_TYPES = ["bug", "建议", "投诉", "其他"]


def _now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


# ===== 提交反馈 =====
@router.post("/api/feedback")
async def submit_feedback(
    body: FeedbackRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    提交用户反馈
    类型：bug/建议/投诉/其他
    """
    if body.feedback_type not in VALID_FEEDBACK_TYPES:
        raise HTTPException(
            status_code=400,
            detail=f"不支持的反馈类型，支持: {', '.join(VALID_FEEDBACK_TYPES)}",
        )

    feedback_id = uuid.uuid4().hex
    now = _now_iso()

    async with get_db_conn() as conn:
        await execute(
            conn,
            """INSERT INTO feedbacks
               (id, user_id, feedback_type, content, contact, screenshot_url,
                status, created_at)
               VALUES (?, ?, ?, ?, ?, ?, 'pending', ?)""",
            (
                feedback_id,
                current_user["id"],
                body.feedback_type,
                body.content,
                body.contact,
                body.screenshot_url,
                now,
            ),
        )

    return {
        "code": 0,
        "message": "反馈已提交，我们会尽快处理",
        "data": {
            "id": feedback_id,
            "feedback_type": body.feedback_type,
            "status": "pending",
            "created_at": now,
        },
    }


# ===== 我的反馈列表 =====
@router.get("/api/feedback/my")
async def my_feedback(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    status: Optional[str] = Query(None, description="pending/processing/resolved/closed"),
    current_user: dict = Depends(get_current_user),
):
    """获取当前用户的反馈列表"""
    offset = (page - 1) * page_size
    conditions = ["user_id = ?"]
    params = [current_user["id"]]

    if status:
        conditions.append("status = ?")
        params.append(status)

    where = " AND ".join(conditions)

    async with get_db_conn() as conn:
        rows = await fetch_all(
            conn,
            f"""SELECT id, feedback_type, content, status, reply, created_at, replied_at
                FROM feedbacks WHERE {where}
                ORDER BY created_at DESC LIMIT ? OFFSET ?""",
            tuple(params + [page_size, offset]),
        )
        total_row = await fetch_one(
            conn,
            f"SELECT COUNT(*) as cnt FROM feedbacks WHERE {where}",
            tuple(params),
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


# ===== 反馈详情 =====
@router.get("/api/feedback/{feedback_id}")
async def get_feedback(
    feedback_id: str,
    current_user: dict = Depends(get_current_user),
):
    """获取反馈详情（含管理员回复）"""
    async with get_db_conn() as conn:
        feedback = await fetch_one(
            conn,
            "SELECT * FROM feedbacks WHERE id = ? AND user_id = ?",
            (feedback_id, current_user["id"]),
        )

    if not feedback:
        raise HTTPException(status_code=404, detail="反馈不存在")

    return {"code": 0, "message": "success", "data": feedback}
