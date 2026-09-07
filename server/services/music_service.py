"""
AI 音乐服务 - MusicService
功能：
- 音乐任务管理（创建/查询/历史）
- 风格/情绪配置
- 上游 API 调用（需配置 ZHIPU_API_KEY）
未配置上游 Key 时任务失败，绝不生成模拟音乐
"""
import os
import uuid
from typing import Dict, Any, Optional, List
from datetime import datetime, timezone

from config import settings
from database import get_db_conn, fetch_one, fetch_all, execute


# ===== 音乐风格配置 =====
MUSIC_STYLES = {
    "pop": {
        "name": "流行",
        "description": "节奏明快、旋律动听的流行音乐",
        "base_bpm": 120,
    },
    "rock": {
        "name": "摇滚",
        "description": "充满力量和激情的摇滚乐",
        "base_bpm": 140,
    },
    "electronic": {
        "name": "电子",
        "description": "现代电子舞曲，节奏感强",
        "base_bpm": 128,
    },
    "classical": {
        "name": "古典",
        "description": "优雅庄重的古典音乐风格",
        "base_bpm": 90,
    },
    "jazz": {
        "name": "爵士",
        "description": "自由即兴的爵士乐",
        "base_bpm": 110,
    },
    "ambient": {
        "name": "氛围",
        "description": "舒缓放松的氛围音乐",
        "base_bpm": 70,
    },
    "hiphop": {
        "name": "嘻哈",
        "description": "节奏鲜明的嘻哈音乐",
        "base_bpm": 95,
    },
    "folk": {
        "name": "民谣",
        "description": "质朴自然的民谣音乐",
        "base_bpm": 100,
    },
}

# ===== 情绪配置 =====
MOODS = {
    "happy": {"name": "欢快", "major_key": True, "tempo_factor": 1.1},
    "sad": {"name": "悲伤", "major_key": False, "tempo_factor": 0.85},
    "calm": {"name": "平静", "major_key": True, "tempo_factor": 0.9},
    "energetic": {"name": "激昂", "major_key": True, "tempo_factor": 1.2},
    "mysterious": {"name": "神秘", "major_key": False, "tempo_factor": 0.95},
    "romantic": {"name": "浪漫", "major_key": True, "tempo_factor": 0.95},
}


class MusicService:
    """AI 音乐生成服务"""

    def __init__(self):
        self.music_dir = os.path.join(settings.MEDIA_DIR, "music")
        os.makedirs(self.music_dir, exist_ok=True)

    async def create_task(
        self,
        user_id: str,
        style: str = "pop",
        mood: str = "happy",
        bpm: Optional[int] = None,
        duration: int = 30,
        title: Optional[str] = None,
    ) -> Dict[str, Any]:
        """创建 AI 音乐生成任务"""
        if style not in MUSIC_STYLES:
            raise ValueError(f"不支持的音乐风格: {style}")
        if mood not in MOODS:
            raise ValueError(f"不支持的情绪: {mood}")

        # 未配置上游 API Key 时直接失败
        if not settings.ZHIPU_API_KEY:
            raise RuntimeError("未配置模型密钥，请在服务端配置 ZHIPU_API_KEY 环境变量")

        duration = max(5, min(300, duration))
        style_config = MUSIC_STYLES[style]
        mood_config = MOODS[mood]
        actual_bpm = bpm if bpm else int(style_config["base_bpm"] * mood_config["tempo_factor"])
        actual_bpm = max(40, min(240, actual_bpm))

        task_id = uuid.uuid4().hex
        now = datetime.now(timezone.utc).isoformat()
        task_title = title or f"{style_config['name']} - {mood_config['name']}"

        # 写入数据库（标记为 failed，因为无真实上游 API）
        async with get_db_conn() as conn:
            await execute(
                conn,
                """INSERT INTO music_tasks
                   (id, user_id, title, style, mood, bpm, duration,
                    status, error, created_at, completed_at)
                   VALUES (?, ?, ?, ?, ?, ?, ?, 'failed', ?, ?, ?)""",
                (task_id, user_id, task_title, style, mood,
                 actual_bpm, duration,
                 "音乐生成上游服务未配置", now, now),
            )

        return {
            "task_id": task_id,
            "title": task_title,
            "style": style,
            "style_name": style_config["name"],
            "mood": mood,
            "mood_name": mood_config["name"],
            "bpm": actual_bpm,
            "duration": duration,
            "status": "failed",
            "error": "音乐生成上游服务未配置",
            "created_at": now,
        }

    async def get_task(self, task_id: str, user_id: str) -> Optional[Dict[str, Any]]:
        """查询音乐生成任务状态"""
        async with get_db_conn() as conn:
            task = await fetch_one(
                conn,
                """SELECT * FROM music_tasks WHERE id = ? AND user_id = ?""",
                (task_id, user_id),
            )
        return task

    async def get_history(
        self,
        user_id: str,
        page: int = 1,
        page_size: int = 20,
        style: Optional[str] = None,
    ) -> Dict[str, Any]:
        """获取音乐生成历史"""
        offset = (page - 1) * page_size
        conditions = ["user_id = ?"]
        params: list = [user_id]

        if style:
            conditions.append("style = ?")
            params.append(style)

        where = " AND ".join(conditions)

        async with get_db_conn() as conn:
            rows = await fetch_all(
                conn,
                f"""SELECT id, title, style, mood, bpm, duration,
                           audio_url, status, created_at
                    FROM music_tasks
                    WHERE {where}
                    ORDER BY created_at DESC LIMIT ? OFFSET ?""",
                tuple(params + [page_size, offset]),
            )
            total_row = await fetch_one(
                conn,
                f"SELECT COUNT(*) as cnt FROM music_tasks WHERE {where}",
                tuple(params),
            )

        return {
            "items": rows,
            "total": total_row["cnt"] if total_row else 0,
            "page": page,
            "page_size": page_size,
        }

    def get_styles(self) -> List[Dict[str, Any]]:
        """获取所有音乐风格"""
        return [
            {"id": sid, "name": s["name"], "description": s["description"],
             "base_bpm": s["base_bpm"]}
            for sid, s in MUSIC_STYLES.items()
        ]

    def get_moods(self) -> List[Dict[str, Any]]:
        """获取所有情绪类型"""
        return [
            {"id": mid, "name": m["name"]}
            for mid, m in MOODS.items()
        ]


# 全局单例
music_service = MusicService()
