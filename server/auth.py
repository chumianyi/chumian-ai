"""
认证模块 - 密码哈希、JWT 创建/验证、当前用户依赖
"""
import hashlib
import secrets
from datetime import datetime, timedelta, timezone
from typing import Optional

from jose import JWTError, jwt
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer

from config import settings
from database import get_db, fetch_one
import aiosqlite


# OAuth2 方案：从 Authorization: Bearer <token> 提取 token
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/auth/login", auto_error=False)


# ===== 密码哈希 =====
def hash_password(password: str) -> str:
    """
    使用 sha256 + 随机 salt 哈希密码
    存储格式：salt$hash
    """
    salt = secrets.token_hex(16)
    password_hash = hashlib.sha256(
        (salt + password).encode("utf-8")
    ).hexdigest()
    return f"{salt}${password_hash}"


def verify_password(password: str, stored_hash: str) -> bool:
    """验证密码是否匹配存储的哈希"""
    try:
        salt, password_hash = stored_hash.split("$", 1)
        computed = hashlib.sha256(
            (salt + password).encode("utf-8")
        ).hexdigest()
        return computed == password_hash
    except (ValueError, AttributeError):
        return False


# ===== JWT =====
def create_access_token(user_id: str, expires_delta: Optional[timedelta] = None) -> str:
    """创建 JWT access token"""
    expire = datetime.now(timezone.utc) + (
        expires_delta or timedelta(days=settings.ACCESS_TOKEN_EXPIRE_DAYS)
    )
    payload = {
        "sub": user_id,
        "exp": expire,
        "iat": datetime.now(timezone.utc),
    }
    return jwt.encode(payload, settings.JWT_SECRET, algorithm=settings.JWT_ALGORITHM)


def decode_access_token(token: str) -> Optional[str]:
    """
    解码 JWT token，返回 user_id
    失败返回 None
    """
    try:
        payload = jwt.decode(
            token, settings.JWT_SECRET, algorithms=[settings.JWT_ALGORITHM]
        )
        return payload.get("sub")
    except JWTError:
        return None


# ===== 依赖注入 =====
async def get_current_user(
    token: Optional[str] = Depends(oauth2_scheme),
    db: aiosqlite.Connection = Depends(get_db),
) -> dict:
    """
    获取当前登录用户（必需认证）
    从 Bearer token 解析用户 ID，查询数据库返回用户信息
    """
    if not token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="未提供认证令牌",
            headers={"WWW-Authenticate": "Bearer"},
        )

    user_id = decode_access_token(token)
    if not user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="认证令牌无效或已过期",
            headers={"WWW-Authenticate": "Bearer"},
        )

    user = await fetch_one(db, "SELECT * FROM users WHERE id = ?", (user_id,))
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="用户不存在",
        )

    # 检查是否被封禁
    if user.get("is_banned"):
        ban_until = user.get("ban_until")
        if ban_until:
            try:
                ban_time = datetime.fromisoformat(ban_until)
                if ban_time > datetime.now(timezone.utc):
                    raise HTTPException(
                        status_code=status.HTTP_403_FORBIDDEN,
                        detail=f"账号已被封禁至 {ban_until}",
                    )
            except (ValueError, TypeError):
                pass
        else:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="账号已被永久封禁",
            )

    return user


async def get_optional_user(
    token: Optional[str] = Depends(oauth2_scheme),
    db: aiosqlite.Connection = Depends(get_db),
) -> Optional[dict]:
    """
    可选认证依赖：允许匿名访问
    有 token 时返回用户，无 token 时返回 None
    """
    if not token:
        return None

    user_id = decode_access_token(token)
    if not user_id:
        return None

    user = await fetch_one(db, "SELECT * FROM users WHERE id = ?", (user_id,))
    return user
