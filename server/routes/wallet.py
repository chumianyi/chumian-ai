"""
钱包路由
余额查询、交易流水、充值、转账给好友
"""
import uuid
from datetime import datetime, timezone
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query

from auth import get_current_user
from models_extra import RechargeRequest, TransferRequest
from database import get_db_conn, fetch_one, fetch_all, execute

router = APIRouter()


def _now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


# ===== 钱包余额 =====
@router.get("/api/wallet")
async def get_wallet(
    current_user: dict = Depends(get_current_user),
):
    """获取钱包余额（积分 + 钻石）"""
    user_id = current_user["id"]

    async with get_db_conn() as conn:
        user = await fetch_one(
            conn,
            "SELECT daily_points, diamonds, total_recharged FROM users WHERE id = ?",
            (user_id,),
        )

    if not user:
        raise HTTPException(status_code=404, detail="用户不存在")

    return {
        "code": 0,
        "message": "success",
        "data": {
            "user_id": user_id,
            "points": user["daily_points"],
            "diamonds": user.get("diamonds", 0),
            "total_recharged": user.get("total_recharged", 0),
        },
    }


# ===== 交易流水 =====
@router.get("/api/wallet/transactions")
async def get_transactions(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    tx_type: Optional[str] = Query(None, description="recharge/consume/transfer_in/transfer_out/refund/achievement"),
    currency: Optional[str] = Query(None, description="points/diamonds"),
    current_user: dict = Depends(get_current_user),
):
    """获取交易流水列表"""
    offset = (page - 1) * page_size
    user_id = current_user["id"]

    conditions = ["user_id = ?"]
    params = [user_id]

    if tx_type:
        conditions.append("type = ?")
        params.append(tx_type)
    if currency:
        conditions.append("currency = ?")
        params.append(currency)

    where = " AND ".join(conditions)

    async with get_db_conn() as conn:
        rows = await fetch_all(
            conn,
            f"""SELECT id, type, amount, currency, description, balance_after, created_at
                FROM wallet_transactions WHERE {where}
                ORDER BY created_at DESC LIMIT ? OFFSET ?""",
            tuple(params + [page_size, offset]),
        )
        total_row = await fetch_one(
            conn,
            f"SELECT COUNT(*) as cnt FROM wallet_transactions WHERE {where}",
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


# ===== 充值 =====
@router.post("/api/wallet/recharge")
async def recharge(
    body: RechargeRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    充值
    生产环境应接入真实支付网关
    """
    user_id = current_user["id"]
    now = _now_iso()
    tx_id = uuid.uuid4().hex

    async with get_db_conn() as conn:
        user = await fetch_one(
            conn, "SELECT daily_points, diamonds, total_recharged FROM users WHERE id = ?", (user_id,)
        )
        if not user:
            raise HTTPException(status_code=404, detail="用户不存在")

        if body.currency == "points":
            new_balance = user["daily_points"] + body.amount
            await execute(
                conn,
                "UPDATE users SET daily_points = ?, total_recharged = ? WHERE id = ?",
                (new_balance, user.get("total_recharged", 0) + body.amount, user_id),
            )
        elif body.currency == "diamonds":
            new_balance = user.get("diamonds", 0) + body.amount
            await execute(
                conn,
                "UPDATE users SET diamonds = ? WHERE id = ?",
                (new_balance, user_id),
            )
        else:
            raise HTTPException(status_code=400, detail="不支持的货币类型")

        # 记录交易
        await execute(
            conn,
            """INSERT INTO wallet_transactions
               (id, user_id, type, amount, currency, description, balance_after, created_at)
               VALUES (?, ?, 'recharge', ?, ?, ?, ?, ?)""",
            (
                tx_id, user_id, body.amount, body.currency,
                f"充值 ({body.payment_method})", new_balance, now,
            ),
        )

        # 同步积分流水
        if body.currency == "points":
            log_id = uuid.uuid4().hex
            await execute(
                conn,
                """INSERT INTO points_log (id, user_id, points, reason, created_at)
                   VALUES (?, ?, ?, ?, ?)""",
                (log_id, user_id, body.amount, "充值", now),
            )

    return {
        "code": 0,
        "message": "充值成功",
        "data": {
            "transaction_id": tx_id,
            "amount": body.amount,
            "currency": body.currency,
            "new_balance": new_balance,
        },
    }


# ===== 转账给好友 =====
@router.post("/api/wallet/transfer")
async def transfer(
    body: TransferRequest,
    current_user: dict = Depends(get_current_user),
):
    """转账积分/钻石给好友"""
    from_user_id = current_user["id"]
    to_user_id = body.to_user_id
    now = _now_iso()

    if from_user_id == to_user_id:
        raise HTTPException(status_code=400, detail="不能给自己转账")

    async with get_db_conn() as conn:
        # 检查是否是好友
        friend = await fetch_one(
            conn,
            "SELECT id FROM friends WHERE user_id = ? AND friend_id = ?",
            (from_user_id, to_user_id),
        )
        if not friend:
            raise HTTPException(status_code=400, detail="只能转账给好友")

        # 检查余额
        if body.currency == "points":
            from_user = await fetch_one(
                conn, "SELECT daily_points FROM users WHERE id = ?", (from_user_id,)
            )
            balance_field = "daily_points"
            from_balance = from_user["daily_points"]
        elif body.currency == "diamonds":
            from_user = await fetch_one(
                conn, "SELECT diamonds FROM users WHERE id = ?", (from_user_id,)
            )
            balance_field = "diamonds"
            from_balance = from_user.get("diamonds", 0)
        else:
            raise HTTPException(status_code=400, detail="不支持的货币类型")

        if from_balance < body.amount:
            raise HTTPException(status_code=400, detail="余额不足")

        # 执行转账
        new_from_balance = from_balance - body.amount
        to_user = await fetch_one(
            conn, f"SELECT {balance_field} FROM users WHERE id = ?", (to_user_id,)
        )
        if not to_user:
            raise HTTPException(status_code=404, detail="接收方用户不存在")

        to_balance = to_user[balance_field] if body.currency == "points" else to_user.get("diamonds", 0)
        new_to_balance = to_balance + body.amount

        await execute(
            conn,
            f"UPDATE users SET {balance_field} = ? WHERE id = ?",
            (new_from_balance, from_user_id),
        )
        await execute(
            conn,
            f"UPDATE users SET {balance_field} = ? WHERE id = ?",
            (new_to_balance, to_user_id),
        )

        # 记录转出交易
        tx_out_id = uuid.uuid4().hex
        await execute(
            conn,
            """INSERT INTO wallet_transactions
               (id, user_id, type, amount, currency, description, balance_after, ref_id, created_at)
               VALUES (?, ?, 'transfer_out', ?, ?, ?, ?, ?, ?)""",
            (
                tx_out_id, from_user_id, body.amount, body.currency,
                f"转账给用户 {to_user_id}: {body.remark or ''}",
                new_from_balance, to_user_id, now,
            ),
        )

        # 记录转入交易
        tx_in_id = uuid.uuid4().hex
        await execute(
            conn,
            """INSERT INTO wallet_transactions
               (id, user_id, type, amount, currency, description, balance_after, ref_id, created_at)
               VALUES (?, ?, 'transfer_in', ?, ?, ?, ?, ?, ?)""",
            (
                tx_in_id, to_user_id, body.amount, body.currency,
                f"收到用户 {from_user_id} 转账: {body.remark or ''}",
                new_to_balance, from_user_id, now,
            ),
        )

        # 同步积分流水
        if body.currency == "points":
            log_out_id = uuid.uuid4().hex
            await execute(
                conn,
                """INSERT INTO points_log (id, user_id, points, reason, created_at)
                   VALUES (?, ?, ?, ?, ?)""",
                (log_out_id, from_user_id, -body.amount, f"转账给 {to_user_id}", now),
            )
            log_in_id = uuid.uuid4().hex
            await execute(
                conn,
                """INSERT INTO points_log (id, user_id, points, reason, created_at)
                   VALUES (?, ?, ?, ?, ?)""",
                (log_in_id, to_user_id, body.amount, f"收到 {from_user_id} 转账", now),
            )

    return {
        "code": 0,
        "message": "转账成功",
        "data": {
            "transaction_id": tx_out_id,
            "amount": body.amount,
            "currency": body.currency,
            "to_user_id": to_user_id,
            "from_balance": new_from_balance,
        },
    }
