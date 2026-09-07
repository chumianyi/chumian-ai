"""
数据库迁移模块 - 服务端扩充模块
新增表结构 + ALTER TABLE 字段扩展 + 版本管理
所有迁移幂等可重复执行
"""
import aiosqlite
from typing import List, Tuple
from database import get_db_conn


# ===== 当前迁移版本 =====
MIGRATION_VERSION = 2


# ===== 新增表 SQL =====
NEW_TABLES_SQL = [
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
]


# ===== 新增 ALTER 字段 =====
NEW_ALTER_COLUMNS: List[Tuple[str, str, str]] = [
    # users 表扩展
    ("users", "diamonds", "INTEGER DEFAULT 0"),
    ("users", "total_recharged", "INTEGER DEFAULT 0"),
    ("users", "last_active_at", "TEXT"),
    # posts 表扩展审核字段
    ("posts", "review_status", "TEXT DEFAULT 'approved'"),
    ("posts", "review_note", "TEXT"),
]


async def run_migrations() -> int:
    """
    执行所有数据库迁移
    返回当前迁移版本号
    """
    async with get_db_conn() as conn:
        # 1. 创建所有新表
        for sql in NEW_TABLES_SQL:
            await conn.execute(sql)

        # 2. 添加新字段（幂等）
        for table, column, col_type in NEW_ALTER_COLUMNS:
            try:
                await conn.execute(
                    f"ALTER TABLE {table} ADD COLUMN {column} {col_type}"
                )
            except Exception:
                pass

        # 3. 初始化成就定义数据
        await _seed_achievements(conn)

        # 4. 记录迁移版本
        from datetime import datetime, timezone
        now = datetime.now(timezone.utc).isoformat()
        await conn.execute(
            "INSERT OR REPLACE INTO schema_migrations (version, applied_at) VALUES (?, ?)",
            (MIGRATION_VERSION, now),
        )

        await conn.commit()

    return MIGRATION_VERSION


async def _seed_achievements(conn: aiosqlite.Connection):
    """初始化内置成就定义（幂等）"""
    from datetime import datetime, timezone
    now = datetime.now(timezone.utc).isoformat()

    achievements = [
        ("first_message", "初次对话", "完成第一次 AI 对话", "💬", "general", 1, 50, 0),
        ("chat_master", "对话达人", "累计完成 100 次对话", "🎯", "general", 100, 500, 0),
        ("first_post", "社区新人", "发布第一篇帖子", "📝", "social", 1, 100, 0),
        ("popular_writer", "人气写手", "帖子累计获得 50 个赞", "⭐", "social", 50, 300, 0),
        ("first_writing", "写作新手", "完成第一篇 AI 写作", "✍️", "creative", 1, 80, 0),
        ("writing_pro", "写作大师", "累计完成 50 篇 AI 写作", "🏆", "creative", 50, 800, 5),
        ("first_image", "绘画入门", "生成第一张 AI 图片", "🎨", "creative", 1, 80, 0),
        ("artist", "数字艺术家", "累计生成 30 张 AI 图片", "🖼️", "creative", 30, 500, 3),
        ("checkin_7", "连续签到 7 天", "连续签到满 7 天", "📅", "explorer", 7, 200, 0),
        ("checkin_30", "月度达人", "连续签到满 30 天", "🔥", "explorer", 30, 1000, 10),
        ("friend_maker", "交友达人", "添加 10 个好友", "🤝", "social", 10, 300, 0),
        ("rich", "小富翁", "钱包积分达到 10000", "💰", "general", 10000, 0, 5),
    ]

    for ach in achievements:
        await conn.execute(
            """INSERT OR IGNORE INTO achievements
               (id, name, description, icon, category, target_value, reward_points, reward_diamonds, created_at)
               VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)""",
            (*ach, now),
        )


async def get_current_version() -> int:
    """获取当前数据库迁移版本"""
    async with get_db_conn() as conn:
        cursor = await conn.execute(
            "SELECT MAX(version) as v FROM schema_migrations"
        )
        row = await cursor.fetchone()
        return row["v"] if row and row["v"] else 0
