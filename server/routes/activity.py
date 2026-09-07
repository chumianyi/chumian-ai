"""
活动路由 - 积分竞猜
"""
import uuid
import random
from datetime import datetime, timezone
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException
import aiosqlite

from models import GuessRequest, GuessResponse
from auth import get_current_user
from database import get_db, fetch_one, fetch_all, execute

router = APIRouter()


def _now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


# ===== 发起竞猜 =====
@router.post("/api/activity/guess", response_model=GuessResponse)
async def create_guess(
    body: GuessRequest,
    current_user: dict = Depends(get_current_user),
    db: aiosqlite.Connection = Depends(get_db),
):
    """
    发起积分竞猜
    押注积分 + 选择答案，系统随机判定结果
    """
    user_id = current_user["id"]

    # 检查积分是否足够
    user_points = current_user.get("daily_points", 0)
    if user_points < body.points:
        raise HTTPException(status_code=400, detail="积分不足")

    # 扣除押注积分
    new_points = user_points - body.points
    await execute(
        db, "UPDATE users SET daily_points = ? WHERE id = ?", (new_points, user_id)
    )

    # 记录积分明细
    log_id = uuid.uuid4().hex
    await execute(
        db,
        """INSERT INTO points_log (id, user_id, points, reason, created_at)
           VALUES (?, ?, ?, ?, ?)""",
        (log_id, user_id, -body.points, f"竞猜押注: {body.question}", _now_iso()),
    )

    # 创建竞猜记录（未结算）
    guess_id = uuid.uuid4().hex
    await execute(
        db,
        """INSERT INTO guesses (id, user_id, question, choice, points, result, settled, created_at)
           VALUES (?, ?, ?, ?, ?, NULL, 0, ?)""",
        (guess_id, user_id, body.question, body.choice, body.points, _now_iso()),
    )

    # 真实随机结算：50% 概率赢，赢了返还双倍
    won = random.choice([True, False])
    result_text = "win" if won else "lose"

    if won:
        winnings = body.points * 2
        final_points = new_points + winnings
        await execute(
            db, "UPDATE users SET daily_points = ? WHERE id = ?", (final_points, user_id)
        )
        # 记录赢取积分
        win_log_id = uuid.uuid4().hex
        await execute(
            db,
            """INSERT INTO points_log (id, user_id, points, reason, created_at)
               VALUES (?, ?, ?, ?, ?)""",
            (win_log_id, user_id, winnings, f"竞猜获胜: {body.question}", _now_iso()),
        )
    else:
        final_points = new_points

    # 更新竞猜结果
    await execute(
        db,
        "UPDATE guesses SET result = ?, settled = 1 WHERE id = ?",
        (result_text, guess_id),
    )

    return GuessResponse(
        id=guess_id,
        question=body.question,
        choice=body.choice,
        points=body.points,
        result=result_text,
        settled=1,
        created_at=_now_iso(),
    )


# ===== 竞猜状态/结果 =====
@router.get("/api/activity/guess/status")
async def guess_status(
    guess_id: Optional[str] = None,
    page: int = 1,
    page_size: int = 20,
    current_user: dict = Depends(get_current_user),
    db: aiosqlite.Connection = Depends(get_db),
):
    """
    获取竞猜状态/结果
    传 guess_id 返回单条，否则返回当前用户的竞猜历史
    """
    user_id = current_user["id"]

    if guess_id:
        guess = await fetch_one(
            db,
            "SELECT * FROM guesses WHERE id = ? AND user_id = ?",
            (guess_id, user_id),
        )
        if not guess:
            raise HTTPException(status_code=404, detail="竞猜记录不存在")
        return guess

    # 返回历史列表
    offset = (page - 1) * page_size
    rows = await fetch_all(
        db,
        """SELECT * FROM guesses WHERE user_id = ?
           ORDER BY created_at DESC LIMIT ? OFFSET ?""",
        (user_id, page_size, offset),
    )

    total = await fetch_one(
        db, "SELECT COUNT(*) as cnt FROM guesses WHERE user_id = ?", (user_id,)
    )

    # 统计胜率
    stats = await fetch_one(
        db,
        """SELECT
           COUNT(*) as total,
           SUM(CASE WHEN result = 'win' THEN 1 ELSE 0 END) as wins,
           SUM(CASE WHEN result = 'lose' THEN 1 ELSE 0 END) as losses
           FROM guesses WHERE user_id = ? AND settled = 1""",
        (user_id,),
    )

    return {
        "items": rows,
        "total": total["cnt"] if total else 0,
        "page": page,
        "page_size": page_size,
        "stats": {
            "total_guesses": stats["total"] if stats else 0,
            "wins": stats["wins"] if stats else 0,
            "losses": stats["losses"] if stats else 0,
            "win_rate": round(
                (stats["wins"] / stats["total"] * 100) if stats and stats["total"] else 0, 1
            ),
        },
    }
