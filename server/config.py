"""
配置模块 - 从环境变量读取所有配置项
"""
import os
import secrets


class Settings:
    """全局配置类，所有配置从环境变量读取，提供合理默认值"""

    # ===== 数据库与媒体 =====
    DB_PATH: str = os.getenv("CHUMIAN_DB_PATH", "data/chumian.db")
    MEDIA_DIR: str = os.getenv("CHUMIAN_MEDIA_DIR", "media")
    PORT: int = int(os.getenv("CHUMIAN_PORT", "24512"))

    # ===== 智谱 LLM 上游 =====
    ZHIPU_API_KEY: str = os.getenv("ZHIPU_API_KEY", "")
    ZHIPU_BASE_URL: str = os.getenv(
        "ZHIPU_BASE_URL", "https://open.bigmodel.cn/api/paas/v4"
    )

    # ===== JWT 认证 =====
    JWT_SECRET: str = os.getenv("JWT_SECRET", "")
    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_DAYS: int = int(
        os.getenv("ACCESS_TOKEN_EXPIRE_DAYS", "30")
    )

    # ===== 联网搜索 =====
    SEARCH_API_KEY: str = os.getenv("SEARCH_API_KEY", "")
    SEARCH_BASE_URL: str = os.getenv(
        "SEARCH_BASE_URL", "https://open.bigmodel.cn/api/paas/v4"
    )

    # ===== 业务常量 =====
    DEFAULT_DAILY_POINTS: int = 90000000
    CHECKIN_POINTS: int = 100
    MAX_CONVERSATION_TITLE_LEN: int = 50

    def __init__(self):
        # 如果未设置 JWT_SECRET，生成一个随机密钥（开发环境）
        if not self.JWT_SECRET:
            self.JWT_SECRET = secrets.token_hex(32)


# 全局单例
settings = Settings()
