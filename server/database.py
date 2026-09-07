"""
数据库模块 - aiosqlite 异步连接、初始化、通用查询辅助
"""
import aiosqlite
from typing import Optional, Any, List, Dict
from contextlib import asynccontextmanager

from config import settings


# 全局数据库连接（单例模式，在 lifespan 中初始化）
_db_conn: Optional[aiosqlite.Connection] = None


async def get_db() -> aiosqlite.Connection:
    """FastAPI 依赖注入：获取数据库连接"""
    global _db_conn
    if _db_conn is None:
        _db_conn = await aiosqlite.connect(settings.DB_PATH)
        _db_conn.row_factory = aiosqlite.Row
    return _db_conn


async def close_db():
    """关闭数据库连接"""
    global _db_conn
    if _db_conn is not None:
        await _db_conn.close()
        _db_conn = None


@asynccontextmanager
async def get_db_conn():
    """上下文管理器形式的数据库连接（用于非请求场景）"""
    conn = await aiosqlite.connect(settings.DB_PATH)
    conn.row_factory = aiosqlite.Row
    try:
        yield conn
    finally:
        await conn.close()


# ===== 建表 SQL =====
CREATE_TABLES_SQL = [
    # 用户表
    """
    CREATE TABLE IF NOT EXISTS users (
        id TEXT PRIMARY KEY,
        email TEXT,
        password_hash TEXT,
        nickname TEXT,
        token TEXT,
        daily_points INTEGER DEFAULT 90000000,
        last_reset TEXT,
        is_banned INTEGER DEFAULT 0,
        ban_until TEXT,
        oobe_completed INTEGER DEFAULT 0,
        created_at TEXT
    )
    """,
    # 会话表
    """
    CREATE TABLE IF NOT EXISTS conversations (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        title TEXT,
        created_at TEXT
    )
    """,
    # 消息表
    """
    CREATE TABLE IF NOT EXISTS messages (
        id TEXT PRIMARY KEY,
        conversation_id TEXT,
        role TEXT,
        content TEXT,
        think_content TEXT,
        model TEXT,
        tokens_used INTEGER DEFAULT 0,
        created_at TEXT
    )
    """,
    # 帖子表
    """
    CREATE TABLE IF NOT EXISTS posts (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        title TEXT,
        content TEXT,
        likes INTEGER DEFAULT 0,
        comments_count INTEGER DEFAULT 0,
        approved INTEGER DEFAULT 0,
        created_at TEXT
    )
    """,
    # 评论表
    """
    CREATE TABLE IF NOT EXISTS comments (
        id TEXT PRIMARY KEY,
        post_id TEXT,
        user_id TEXT,
        content TEXT,
        created_at TEXT
    )
    """,
    # 帖子点赞表
    """
    CREATE TABLE IF NOT EXISTS post_likes (
        id TEXT PRIMARY KEY,
        post_id TEXT,
        user_id TEXT,
        created_at TEXT
    )
    """,
    # Agent 表
    """
    CREATE TABLE IF NOT EXISTS agents (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        name TEXT,
        description TEXT,
        system_prompt TEXT,
        avatar TEXT,
        created_at TEXT
    )
    """,
    # 积分明细表（新增）
    """
    CREATE TABLE IF NOT EXISTS points_log (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        points INTEGER,
        reason TEXT,
        created_at TEXT
    )
    """,
    # 签到表（新增）
    """
    CREATE TABLE IF NOT EXISTS checkins (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        checkin_date TEXT,
        points INTEGER,
        streak INTEGER DEFAULT 1,
        created_at TEXT
    )
    """,
    # 关注关系表（新增）
    """
    CREATE TABLE IF NOT EXISTS follows (
        id TEXT PRIMARY KEY,
        follower_id TEXT,
        following_id TEXT,
        created_at TEXT
    )
    """,
    # 通知表（新增）
    """
    CREATE TABLE IF NOT EXISTS notifications (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        type TEXT,
        title TEXT,
        content TEXT,
        is_read INTEGER DEFAULT 0,
        created_at TEXT
    )
    """,
    # 竞猜表（新增）
    """
    CREATE TABLE IF NOT EXISTS guesses (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        question TEXT,
        choice TEXT,
        points INTEGER,
        result TEXT,
        settled INTEGER DEFAULT 0,
        created_at TEXT
    )
    """,
    # Agent 点赞表（新增）
    """
    CREATE TABLE IF NOT EXISTS agent_likes (
        id TEXT PRIMARY KEY,
        agent_id TEXT,
        user_id TEXT,
        created_at TEXT
    )
    """,
    # ===== 扩充模块表 =====
    # AI 写作任务表
    """
    CREATE TABLE IF NOT EXISTS writing_tasks (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        writing_type TEXT NOT NULL,
        topic TEXT NOT NULL,
        params TEXT DEFAULT '{}',
        status TEXT DEFAULT 'pending',
        result TEXT,
        error TEXT,
        tokens_used INTEGER DEFAULT 0,
        created_at TEXT,
        completed_at TEXT
    )
    """,
    # AI 绘画任务表
    """
    CREATE TABLE IF NOT EXISTS image_tasks (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        prompt TEXT NOT NULL,
        style TEXT DEFAULT '写实',
        size TEXT DEFAULT '1024x1024',
        negative_prompt TEXT,
        status TEXT DEFAULT 'pending',
        image_url TEXT,
        error TEXT,
        created_at TEXT,
        completed_at TEXT
    )
    """,
    # 用户反馈表
    """
    CREATE TABLE IF NOT EXISTS feedbacks (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        feedback_type TEXT NOT NULL,
        content TEXT NOT NULL,
        contact TEXT,
        screenshot_url TEXT,
        status TEXT DEFAULT 'pending',
        reply TEXT,
        replied_at TEXT,
        created_at TEXT
    )
    """,
    # 推送设备表
    """
    CREATE TABLE IF NOT EXISTS push_devices (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        device_token TEXT NOT NULL,
        platform TEXT NOT NULL,
        device_model TEXT,
        enabled INTEGER DEFAULT 1,
        last_active TEXT,
        created_at TEXT,
        UNIQUE(user_id, device_token)
    )
    """,
    # 推送设置表
    """
    CREATE TABLE IF NOT EXISTS push_settings (
        user_id TEXT PRIMARY KEY,
        enabled INTEGER DEFAULT 1,
        message_push INTEGER DEFAULT 1,
        system_push INTEGER DEFAULT 1,
        marketing_push INTEGER DEFAULT 0,
        updated_at TEXT
    )
    """,
    # 好友关系表
    """
    CREATE TABLE IF NOT EXISTS friends (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        friend_id TEXT NOT NULL,
        added_at TEXT,
        UNIQUE(user_id, friend_id)
    )
    """,
    # 好友请求表
    """
    CREATE TABLE IF NOT EXISTS friend_requests (
        id TEXT PRIMARY KEY,
        from_user_id TEXT NOT NULL,
        to_user_id TEXT NOT NULL,
        message TEXT,
        status TEXT DEFAULT 'pending',
        created_at TEXT,
        handled_at TEXT
    )
    """,
    # 成就定义表
    """
    CREATE TABLE IF NOT EXISTS achievements (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        icon TEXT,
        category TEXT DEFAULT 'general',
        target_value INTEGER DEFAULT 1,
        reward_points INTEGER DEFAULT 0,
        reward_diamonds INTEGER DEFAULT 0,
        created_at TEXT
    )
    """,
    # 用户成就表
    """
    CREATE TABLE IF NOT EXISTS user_achievements (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        achievement_id TEXT NOT NULL,
        current_value INTEGER DEFAULT 0,
        unlocked INTEGER DEFAULT 0,
        claimed INTEGER DEFAULT 0,
        unlocked_at TEXT,
        claimed_at TEXT,
        UNIQUE(user_id, achievement_id)
    )
    """,
    # 钱包交易流水表
    """
    CREATE TABLE IF NOT EXISTS wallet_transactions (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        type TEXT NOT NULL,
        amount INTEGER NOT NULL,
        currency TEXT DEFAULT 'points',
        description TEXT,
        balance_after INTEGER DEFAULT 0,
        ref_id TEXT,
        created_at TEXT
    )
    """,
    # 数据分析事件表
    """
    CREATE TABLE IF NOT EXISTS analytics_events (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        event_type TEXT NOT NULL,
        event_name TEXT NOT NULL,
        properties TEXT DEFAULT '{}',
        ip TEXT,
        user_agent TEXT,
        created_at TEXT
    )
    """,
    # 管理员操作日志表
    """
    CREATE TABLE IF NOT EXISTS admin_logs (
        id TEXT PRIMARY KEY,
        admin_id TEXT NOT NULL,
        action TEXT NOT NULL,
        target_type TEXT,
        target_id TEXT,
        detail TEXT,
        ip TEXT,
        created_at TEXT
    )
    """,
    # 内容审核队列表
    """
    CREATE TABLE IF NOT EXISTS content_reviews (
        id TEXT PRIMARY KEY,
        content_type TEXT NOT NULL,
        content_id TEXT NOT NULL,
        user_id TEXT,
        content TEXT,
        auto_result TEXT,
        auto_score REAL,
        status TEXT DEFAULT 'pending',
        reviewer_id TEXT,
        review_note TEXT,
        created_at TEXT,
        reviewed_at TEXT
    )
    """,
    # 迁移版本表
    """
    CREATE TABLE IF NOT EXISTS schema_migrations (
        version INTEGER PRIMARY KEY,
        applied_at TEXT NOT NULL
    )
    """,
    # ===== 新增模块表 =====
    # 语音任务表（TTS/STT）
    """
    CREATE TABLE IF NOT EXISTS voice_tasks (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        task_type TEXT NOT NULL,
        text TEXT,
        voice_id TEXT DEFAULT 'default',
        speed REAL DEFAULT 1.0,
        pitch REAL DEFAULT 1.0,
        audio_url TEXT,
        duration REAL DEFAULT 0,
        file_size INTEGER DEFAULT 0,
        status TEXT DEFAULT 'pending',
        error TEXT,
        created_at TEXT,
        completed_at TEXT
    )
    """,
    # AI 音乐任务表
    """
    CREATE TABLE IF NOT EXISTS music_tasks (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        title TEXT,
        style TEXT NOT NULL,
        mood TEXT NOT NULL,
        bpm INTEGER DEFAULT 120,
        duration INTEGER DEFAULT 30,
        audio_url TEXT,
        file_size INTEGER DEFAULT 0,
        status TEXT DEFAULT 'pending',
        error TEXT,
        created_at TEXT,
        completed_at TEXT
    )
    """,
    # 导出任务表
    """
    CREATE TABLE IF NOT EXISTS export_tasks (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        conversation_id TEXT NOT NULL,
        format TEXT NOT NULL,
        include_metadata INTEGER DEFAULT 1,
        file_url TEXT,
        file_size INTEGER DEFAULT 0,
        message_count INTEGER DEFAULT 0,
        status TEXT DEFAULT 'pending',
        error TEXT,
        created_at TEXT,
        completed_at TEXT
    )
    """,
    # 插件安装记录表
    """
    CREATE TABLE IF NOT EXISTS plugin_installs (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        plugin_id TEXT NOT NULL,
        config TEXT DEFAULT '{}',
        installed_at TEXT,
        UNIQUE(user_id, plugin_id)
    )
    """,
    # 积分商城商品表
    """
    CREATE TABLE IF NOT EXISTS shop_items (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        price INTEGER NOT NULL,
        icon TEXT,
        type TEXT DEFAULT 'virtual',
        stock INTEGER DEFAULT -1,
        is_active INTEGER DEFAULT 1,
        created_at TEXT
    )
    """,
]


# ===== ALTER TABLE 添加缺失字段 =====
ALTER_COLUMNS = [
    # posts 表新增字段
    ("posts", "type", "TEXT DEFAULT 'text'"),
    ("posts", "media_url", "TEXT"),
    ("posts", "agent_id", "TEXT"),
    # agents 表新增字段
    ("agents", "likes", "INTEGER DEFAULT 0"),
    ("agents", "is_published", "INTEGER DEFAULT 0"),
    ("agents", "opening_message", "TEXT"),
    # users 表新增字段
    ("users", "avatar", "TEXT"),
    ("users", "vip_status", "INTEGER DEFAULT 0"),
    ("users", "qq", "TEXT"),
    ("users", "birthday", "TEXT"),
    # 扩充模块新增字段
    ("users", "diamonds", "INTEGER DEFAULT 0"),
    ("users", "total_recharged", "INTEGER DEFAULT 0"),
    ("users", "last_active_at", "TEXT"),
    ("posts", "review_status", "TEXT DEFAULT 'approved'"),
    ("posts", "review_note", "TEXT"),
]


async def init_db():
    """
    初始化数据库：
    1. 创建所有表（IF NOT EXISTS）
    2. ALTER TABLE 添加缺失字段（try-except 忽略重复列错误）
    """
    async with get_db_conn() as conn:
        # 1. 创建所有表
        for sql in CREATE_TABLES_SQL:
            await conn.execute(sql)

        # 2. 添加缺失字段
        for table, column, col_type in ALTER_COLUMNS:
            try:
                await conn.execute(
                    f"ALTER TABLE {table} ADD COLUMN {column} {col_type}"
                )
            except Exception:
                # 列已存在时忽略错误
                pass

        await conn.commit()

        # 3. 初始化商品数据（初始化数据，非模拟）
        await _seed_shop_items(conn)


async def _seed_shop_items(conn: aiosqlite.Connection):
    """初始化积分商城商品（初始化数据，幂等）"""
    from datetime import datetime, timezone
    now = datetime.now(timezone.utc).isoformat()

    # 检查是否已有商品数据
    cursor = await conn.execute("SELECT COUNT(*) as cnt FROM shop_items")
    row = await cursor.fetchone()
    if row["cnt"] > 0:
        return

    initial_items = [
        ("item_daily_points", "每日积分加成卡", "使用后当日积分上限提升 50%", 500, "🎁", "virtual", -1, 1),
        ("item_avatar_frame", "专属头像框", "炫酷的金色头像框，彰显个性", 2000, "👑", "virtual", -1, 1),
        ("item_theme", "深色主题皮肤", "护眼深色模式，夜间使用更舒适", 1000, "🌙", "virtual", -1, 1),
        ("item_sticker_pack", "表情包合集", "50+ 精选表情包，聊天更有趣", 800, "😀", "virtual", -1, 1),
        ("item_svip_month", "SVIP 月卡", "30 天超级会员，享受全部特权", 9800, "💎", "svip", -1, 1),
    ]

    for item in initial_items:
        await conn.execute(
            """INSERT OR IGNORE INTO shop_items
               (id, name, description, price, icon, type, stock, is_active, created_at)
               VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)""",
            (*item, now),
        )
    await conn.commit()


# ===== 通用查询辅助函数 =====
async def fetch_one(
    conn: aiosqlite.Connection, query: str, params: tuple = ()
) -> Optional[Dict[str, Any]]:
    """执行查询并返回单行结果（字典形式）"""
    cursor = await conn.execute(query, params)
    row = await cursor.fetchone()
    return dict(row) if row else None


async def fetch_all(
    conn: aiosqlite.Connection, query: str, params: tuple = ()
) -> List[Dict[str, Any]]:
    """执行查询并返回所有结果（字典列表）"""
    cursor = await conn.execute(query, params)
    rows = await cursor.fetchall()
    return [dict(row) for row in rows]


async def execute(
    conn: aiosqlite.Connection, query: str, params: tuple = ()
) -> int:
    """执行写入操作，返回 lastrowid"""
    cursor = await conn.execute(query, params)
    await conn.commit()
    return cursor.lastrowid


async def execute_many(
    conn: aiosqlite.Connection, query: str, params_list: list
):
    """批量执行写入操作"""
    await conn.executemany(query, params_list)
    await conn.commit()
