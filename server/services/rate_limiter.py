"""
API 限流服务 - RateLimiter
支持两种算法：
1. 滑动窗口（Sliding Window）- 按时间窗口计数
2. 令牌桶（Token Bucket）- 恒定速率补充令牌

限流维度：
- 按用户 ID（user_id）
- 按 IP 地址
- 按 API 端点
"""
import time
import asyncio
from collections import defaultdict, deque
from typing import Dict, Deque, Optional, Tuple
from fastapi import Request, HTTPException, status


class SlidingWindowLimiter:
    """
    滑动窗口限流器
    记录每个 key 在窗口内的请求时间戳
    """

    def __init__(self, max_requests: int = 60, window_seconds: int = 60):
        self.max_requests = max_requests
        self.window_seconds = window_seconds
        self._requests: Dict[str, Deque[float]] = defaultdict(deque)
        self._lock = asyncio.Lock()

    async def allow(self, key: str) -> Tuple[bool, Dict[str, int]]:
        """
        检查是否允许请求
        返回 (是否允许, 限流信息)
        """
        now = time.time()
        window_start = now - self.window_seconds

        async with self._lock:
            dq = self._requests[key]
            # 移除窗口外的记录
            while dq and dq[0] < window_start:
                dq.popleft()

            current = len(dq)
            if current >= self.max_requests:
                retry_after = int(dq[0] + self.window_seconds - now) + 1
                return False, {
                    "limit": self.max_requests,
                    "remaining": 0,
                    "retry_after": max(retry_after, 1),
                }

            dq.append(now)
            return True, {
                "limit": self.max_requests,
                "remaining": self.max_requests - current - 1,
                "retry_after": 0,
            }

    async def reset(self, key: str):
        """重置某个 key 的计数"""
        async with self._lock:
            self._requests.pop(key, None)


class TokenBucketLimiter:
    """
    令牌桶限流器
    以恒定速率补充令牌，突发流量可消耗桶内积累令牌
    """

    def __init__(self, rate: float = 10.0, capacity: int = 20):
        self.rate = rate  # 每秒补充令牌数
        self.capacity = capacity  # 桶容量
        self._tokens: Dict[str, float] = {}
        self._last_refill: Dict[str, float] = {}
        self._lock = asyncio.Lock()

    async def allow(self, key: str, tokens_needed: int = 1) -> Tuple[bool, Dict[str, float]]:
        """检查是否有足够令牌"""
        now = time.time()

        async with self._lock:
            if key not in self._tokens:
                self._tokens[key] = float(self.capacity)
                self._last_refill[key] = now

            # 补充令牌
            elapsed = now - self._last_refill[key]
            new_tokens = elapsed * self.rate
            self._tokens[key] = min(
                self.capacity, self._tokens[key] + new_tokens
            )
            self._last_refill[key] = now

            if self._tokens[key] >= tokens_needed:
                self._tokens[key] -= tokens_needed
                return True, {
                    "tokens": self._tokens[key],
                    "capacity": self.capacity,
                    "rate": self.rate,
                }

            needed = tokens_needed - self._tokens[key]
            wait_time = needed / self.rate
            return False, {
                "tokens": self._tokens[key],
                "capacity": self.capacity,
                "rate": self.rate,
                "retry_after": round(wait_time, 2),
            }


class RateLimiter:
    """
    综合限流器 - 对外统一接口
    内置多个限流器实例，按场景使用
    """

    def __init__(self):
        # 通用 API 限流：每用户每分钟 120 次
        self.api_limiter = SlidingWindowLimiter(max_requests=120, window_seconds=60)
        # 写作生成限流：每用户每小时 20 次
        self.writing_limiter = SlidingWindowLimiter(max_requests=20, window_seconds=3600)
        # 绘画生成限流：每用户每小时 10 次
        self.image_limiter = SlidingWindowLimiter(max_requests=10, window_seconds=3600)
        # 登录限流：每 IP 每分钟 5 次
        self.login_limiter = SlidingWindowLimiter(max_requests=5, window_seconds=60)
        # 上传限流：令牌桶，每秒 2 个，容量 5
        self.upload_limiter = TokenBucketLimiter(rate=2.0, capacity=5)

    async def check(
        self,
        limiter_name: str,
        key: str,
    ) -> None:
        """
        限流检查，超限抛出 429 HTTPException
        """
        limiter = getattr(self, f"{limiter_name}_limiter", None)
        if limiter is None:
            return

        allowed, info = await limiter.allow(key)
        if not allowed:
            retry_after = info.get("retry_after", 60)
            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail=f"请求过于频繁，请在 {retry_after} 秒后重试",
                headers={
                    "Retry-After": str(retry_after),
                    "X-RateLimit-Limit": str(info.get("limit", info.get("capacity", 0))),
                    "X-RateLimit-Remaining": str(info.get("remaining", info.get("tokens", 0))),
                },
            )

    @staticmethod
    def get_client_ip(request: Request) -> str:
        """从请求中提取客户端 IP"""
        forwarded = request.headers.get("x-forwarded-for")
        if forwarded:
            return forwarded.split(",")[0].strip()
        return request.client.host if request.client else "unknown"

    @staticmethod
    def get_user_key(user_id: str, endpoint: str = "") -> str:
        """构造用户维度限流 key"""
        return f"user:{user_id}:{endpoint}" if endpoint else f"user:{user_id}"


# 全局单例
rate_limiter = RateLimiter()
