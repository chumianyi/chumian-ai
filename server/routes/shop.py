"""
积分商城路由 - 签到、签到状态、积分兑换、SVIP购买、商品列表
商品数据从数据库 shop_items 表读取，不写死假商品
"""
import uuid
from datetime import datetime, timezone, date
from typing import List

from fastapi import APIRouter, Depends, HTTPException
import aiosqlite

from models import CheckinResponse, ShopItem, ExchangeRequest
from auth import get_current_user
from database import get_db, fetch_one, fetch_all, execute
from config import settings

router = APIRouter()


def _now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def _today_str() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%d")


# ===== 签到 =====
@router.post("/api/checkin", response_model=CheckinResponse)
async def checkin(
    current_user: dict = Depends(get_current_user),
    db: aiosqlite.Connection = Depends(get_db),
):
    """
    每日签到
    返回获得积分、连续签到天数、当前总积分
    """
    user_id = current_user["id"]
    today = _today_str()

    # 检查今天是否已签到
    existing = await fetch_one(
        db,
        "SELECT id FROM checkins WHERE user_id = ? AND checkin_date = ?",
        (user_id, today),
    )
    if existing:
        raise HTTPException(status_code=400, detail="今天已经签到过了")

    # 计算连续签到天数
    yesterday = (datetime.now(timezone.utc).fromordinal(
        datetime.now(timezone.utc).toordinal() - 1
    )).strftime("%Y-%m-%d")

    last_checkin = await fetch_one(
        db,
        "SELECT streak FROM checkins WHERE user_id = ? AND checkin_date = ?",
        (user_id, yesterday),
    )
    streak = (last_checkin["streak"] + 1) if last_checkin else 1

    # 计算签到积分（基础 100 + 连续签到奖励）
    base_points = settings.CHECKIN_POINTS
    bonus = min((streak - 1) * 10, 100)  # 连续签到每天多 10 分，最多 100
    points_earned = base_points + bonus

    # 记录签到
    checkin_id = uuid.uuid4().hex
    await execute(
        db,
        """INSERT INTO checkins (id, user_id, checkin_date, points, streak, created_at)
           VALUES (?, ?, ?, ?, ?, ?)""",
        (checkin_id, user_id, today, points_earned, streak, _now_iso()),
    )

    # 更新用户积分
    new_points = current_user.get("daily_points", 0) + points_earned
    await execute(
        db, "UPDATE users SET daily_points = ? WHERE id = ?", (new_points, user_id)
    )

    # 记录积分明细
    log_id = uuid.uuid4().hex
    await execute(
        db,
        """INSERT INTO points_log (id, user_id, points, reason, created_at)
           VALUES (?, ?, ?, ?, ?)""",
        (log_id, user_id, points_earned, f"每日签到(连续{streak}天)", _now_iso()),
    )

    return CheckinResponse(
        points=points_earned,
        streak=streak,
        total_points=new_points,
    )


# ===== 签到状态 =====
@router.get("/api/checkin/status")
async def checkin_status(
    current_user: dict = Depends(get_current_user),
    db: aiosqlite.Connection = Depends(get_db),
):
    """获取签到状态：今天是否已签到、连续签到天数、本月签到记录"""
    user_id = current_user["id"]
    today = _today_str()

    # 今天是否已签到
    today_checkin = await fetch_one(
        db,
        "SELECT * FROM checkins WHERE user_id = ? AND checkin_date = ?",
        (user_id, today),
    )

    # 获取最近的签到记录计算连续天数
    recent = await fetch_all(
        db,
        """SELECT checkin_date, streak FROM checkins
           WHERE user_id = ? ORDER BY checkin_date DESC LIMIT 2""",
        (user_id,),
    )

    current_streak = 0
    if today_checkin:
        current_streak = today_checkin["streak"]
    elif recent and recent[0]["checkin_date"] == (
        datetime.now(timezone.utc).fromordinal(
            datetime.now(timezone.utc).toordinal() - 1
        )
    ).strftime("%Y-%m-%d"):
        current_streak = recent[0]["streak"]

    # 本月签到天数
    month_start = datetime.now(timezone.utc).strftime("%Y-%m-01")
    month_count = await fetch_one(
        db,
        "SELECT COUNT(*) as cnt FROM checkins WHERE user_id = ? AND checkin_date >= ?",
        (user_id, month_start),
    )

    return {
        "checked_in_today": today_checkin is not None,
        "current_streak": current_streak,
        "month_checkin_count": month_count["cnt"] if month_count else 0,
        "today_points": today_checkin["points"] if today_checkin else 0,
        "base_points": settings.CHECKIN_POINTS,
    }


# ===== 商品列表（从数据库读取） =====
@router.get("/api/shop/items")
async def list_shop_items(
    db: aiosqlite.Connection = Depends(get_db),
):
    """获取积分商城商品列表（从数据库 shop_items 表读取）"""
    rows = await fetch_all(
        db,
        "SELECT id, name, description, price, icon, type FROM shop_items WHERE is_active = 1 ORDER BY price ASC",
    )
    return {"items": rows, "total": len(rows)}


# ===== 积分兑换 =====
@router.post("/api/shop/exchange")
async def exchange_item(
    body: ExchangeRequest,
    current_user: dict = Depends(get_current_user),
    db: aiosqlite.Connection = Depends(get_db),
):
    """使用积分兑换商品"""
    # 从数据库查找商品
    item = await fetch_one(
        db,
        "SELECT * FROM shop_items WHERE id = ? AND is_active = 1",
        (body.item_id,),
    )
    if not item:
        raise HTTPException(status_code=404, detail="商品不存在")

    # 检查库存（-1 表示无限库存）
    if item["stock"] != -1 and item["stock"] <= 0:
        raise HTTPException(status_code=400, detail="商品已售罄")

    # 检查积分是否足够
    user_points = current_user.get("daily_points", 0)
    if user_points < item["price"]:
        raise HTTPException(status_code=400, detail="积分不足")

    # 扣除积分
    new_points = user_points - item["price"]
    await execute(
        db, "UPDATE users SET daily_points = ? WHERE id = ?",
        (new_points, current_user["id"]),
    )

    # 扣减库存（有限库存时）
    if item["stock"] != -1:
        await execute(
            db, "UPDATE shop_items SET stock = stock - 1 WHERE id = ?",
            (item["id"],),
        )

    # 记录积分明细
    log_id = uuid.uuid4().hex
    await execute(
        db,
        """INSERT INTO points_log (id, user_id, points, reason, created_at)
           VALUES (?, ?, ?, ?, ?)""",
        (log_id, current_user["id"], -item["price"], f"兑换商品: {item['name']}", _now_iso()),
    )

    # 发送通知
    notif_id = uuid.uuid4().hex
    await execute(
        db,
        """INSERT INTO notifications (id, user_id, type, title, content, is_read, created_at)
           VALUES (?, ?, 'exchange', '兑换成功', ?, 0, ?)""",
        (notif_id, current_user["id"],
         f"成功兑换 {item['name']}，消耗 {item['price']} 积分", _now_iso()),
    )

    return {
        "message": "兑换成功",
        "item_name": item["name"],
        "points_spent": item["price"],
        "remaining_points": new_points,
    }


# ===== 购买 SVIP =====
@router.post("/api/shop/svip")
async def purchase_svip(
    current_user: dict = Depends(get_current_user),
    db: aiosqlite.Connection = Depends(get_db),
):
    """
    购买 SVIP
    实际项目中应接入支付，此处直接标记为 SVIP
    """
    # 检查是否已是 SVIP
    if current_user.get("vip_status", 0) == 1:
        raise HTTPException(status_code=400, detail="您已经是 SVIP 会员")

    # 标记为 SVIP
    await execute(
        db, "UPDATE users SET vip_status = 1 WHERE id = ?", (current_user["id"],)
    )

    # 发送通知
    notif_id = uuid.uuid4().hex
    await execute(
        db,
        """INSERT INTO notifications (id, user_id, type, title, content, is_read, created_at)
           VALUES (?, ?, 'svip', 'SVIP 开通成功', ?, 0, ?)""",
        (notif_id, current_user["id"],
         "恭喜您成为 SVIP 会员，享受全部特权！", _now_iso()),
    )

    return {"message": "SVIP 开通成功", "vip_status": 1}
