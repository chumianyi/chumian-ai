"""
认证路由 - 注册、登录、登出、新手引导、App验证
"""
import uuid
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, status
import aiosqlite

from models import UserCreate, UserLogin, TokenResponse, BaseResponse
from auth import hash_password, verify_password, create_access_token, get_current_user
from database import get_db, fetch_one, execute

router = APIRouter()


def _now_iso() -> str:
    """获取当前时间 ISO 格式字符串"""
    return datetime.now(timezone.utc).isoformat()


@router.post("/api/verify-app")
async def verify_app():
    """
    验证 App 合法性
    客户端启动时调用，返回 valid:true 表示服务端正常
    """
    return {"valid": True, "server_time": _now_iso(), "version": "1.0.0"}


@router.post("/api/auth/register", response_model=TokenResponse)
async def register(
    body: UserCreate,
    db: aiosqlite.Connection = Depends(get_db),
):
    """
    用户注册
    接收 email/密码/昵称，创建用户，返回 token + user_id
    """
    # 检查邮箱是否已注册
    existing = await fetch_one(
        db, "SELECT id FROM users WHERE email = ?", (body.email,)
    )
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="该邮箱已被注册",
        )

    # 创建用户
    user_id = uuid.uuid4().hex
    password_hash = hash_password(body.password)
    nickname = body.nickname or f"用户{user_id[:8]}"
    created_at = _now_iso()

    await execute(
        db,
        """INSERT INTO users (id, email, password_hash, nickname, token,
           daily_points, last_reset, is_banned, oobe_completed, created_at)
           VALUES (?, ?, ?, ?, ?, ?, ?, 0, 0, ?)""",
        (user_id, body.email, password_hash, nickname, "",
         90000000, created_at, created_at),
    )

    # 生成 JWT token
    access_token = create_access_token(user_id)

    # 更新用户 token 字段
    await execute(
        db, "UPDATE users SET token = ? WHERE id = ?", (access_token, user_id)
    )

    return TokenResponse(
        access_token=access_token,
        token_type="bearer",
        user_id=user_id,
        nickname=nickname,
        oobe_completed=0,
    )


@router.post("/api/auth/login", response_model=TokenResponse)
async def login(
    body: UserLogin,
    db: aiosqlite.Connection = Depends(get_db),
):
    """
    用户登录
    验证密码，返回 token + user_id + nickname + oobe_completed
    """
    # 查找用户
    user = await fetch_one(
        db, "SELECT * FROM users WHERE email = ?", (body.email,)
    )
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="邮箱或密码错误",
        )

    # 验证密码
    if not verify_password(body.password, user["password_hash"]):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="邮箱或密码错误",
        )

    # 检查是否被封禁
    if user.get("is_banned"):
        ban_until = user.get("ban_until")
        if ban_until:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"账号已被封禁至 {ban_until}",
            )
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="账号已被永久封禁",
        )

    # 生成新 token
    access_token = create_access_token(user["id"])
    await execute(
        db, "UPDATE users SET token = ? WHERE id = ?", (access_token, user["id"])
    )

    return TokenResponse(
        access_token=access_token,
        token_type="bearer",
        user_id=user["id"],
        nickname=user["nickname"],
        oobe_completed=user.get("oobe_completed", 0),
    )


@router.post("/api/auth/logout")
async def logout(
    current_user: dict = Depends(get_current_user),
    db: aiosqlite.Connection = Depends(get_db),
):
    """
    用户登出
    清除用户 token 字段
    """
    await execute(
        db, "UPDATE users SET token = '' WHERE id = ?", (current_user["id"],)
    )
    return {"message": "登出成功"}


@router.post("/api/auth/complete-oobe")
async def complete_oobe(
    current_user: dict = Depends(get_current_user),
    db: aiosqlite.Connection = Depends(get_db),
):
    """
    完成新手引导
    将用户 oobe_completed 标记为 1
    """
    await execute(
        db,
        "UPDATE users SET oobe_completed = 1 WHERE id = ?",
        (current_user["id"],),
    )
    return {"message": "新手引导已完成", "oobe_completed": 1}
