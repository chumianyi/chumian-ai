"""
数据分析服务 - AnalyticsService
功能：
- 事件存储（批量/单条）
- 统计计算（用户使用概览）
- 趋势分析（7天/30天）
- 数据聚合
- 简单内存缓存
"""
import uuid
import json
import time
from typing import Dict, Any, Optional, List, Tuple
from datetime import datetime, timezone, timedelta

from database import get_db_conn, fetch_one, fetch_all, execute, execute_many


class AnalyticsService:
    """数据分析服务"""

    def __init__(self):
        # 简单缓存：{cache_key: (expire_ts, data)}
        self._cache: Dict[str, Tuple[float, Any]] = {}
        self._cache_ttl = 60  # 缓存 60 秒

    def _cache_get(self, key: str) -> Optional[Any]:
        """从缓存获取"""
        item = self._cache.get(key)
        if item and item[0] > time.time():
            return item[1]
        if key in self._cache:
            del self._cache[key]
        return None

    def _cache_set(self, key: str, data: Any):
        """写入缓存"""
        self._cache[key] = (time.time() + self._cache_ttl, data)

    def _cache_invalidate(self, prefix: str = ""):
        """清除指定前缀的缓存"""
        if not prefix:
            self._cache.clear()
            return
        keys = [k for k in self._cache if k.startswith(prefix)]
        for k in keys:
            del self._cache[k]

    async def track_event(
        self,
        user_id: Optional[str],
        event_type: str,
        event_name: str,
        properties: Optional[Dict[str, Any]] = None,
        ip: Optional[str] = None,
        user_agent: Optional[str] = None,
    ) -> str:
        """记录单个事件"""
        event_id = uuid.uuid4().hex
        now = datetime.now(timezone.utc).isoformat()

        async with get_db_conn() as conn:
            await execute(
                conn,
                """INSERT INTO analytics_events
                   (id, user_id, event_type, event_name, properties, ip, user_agent, created_at)
                   VALUES (?, ?, ?, ?, ?, ?, ?, ?)""",
                (
                    event_id, user_id, event_type, event_name,
                    json.dumps(properties or {}, ensure_ascii=False),
                    ip, user_agent, now,
                ),
            )

        self._cache_invalidate(f"summary:{user_id}")
        return event_id

    async def track_events_batch(
        self,
        user_id: Optional[str],
        events: List[Dict[str, Any]],
        ip: Optional[str] = None,
        user_agent: Optional[str] = None,
    ) -> int:
        """批量记录事件，返回成功数量"""
        now = datetime.now(timezone.utc).isoformat()
        params_list = []

        for evt in events:
            event_id = uuid.uuid4().hex
            params_list.append((
                event_id,
                user_id,
                evt.get("event_type", "custom"),
                evt.get("event_name", "unknown"),
                json.dumps(evt.get("properties", {}), ensure_ascii=False),
                ip,
                user_agent,
                evt.get("timestamp", now),
            ))

        async with get_db_conn() as conn:
            await execute_many(
                conn,
                """INSERT INTO analytics_events
                   (id, user_id, event_type, event_name, properties, ip, user_agent, created_at)
                   VALUES (?, ?, ?, ?, ?, ?, ?, ?)""",
                params_list,
            )

        self._cache_invalidate(f"summary:{user_id}")
        return len(params_list)

    async def get_user_summary(self, user_id: str) -> Dict[str, Any]:
        """
        获取用户使用统计
        包含：对话数/消息数/积分消耗/活跃天数/写作数/绘画数
        """
        cache_key = f"summary:{user_id}"
        cached = self._cache_get(cache_key)
        if cached:
            return cached

        async with get_db_conn() as conn:
            # 对话数
            conv_row = await fetch_one(
                conn,
                "SELECT COUNT(*) as cnt FROM conversations WHERE user_id = ?",
                (user_id,),
            )
            # 消息数（通过 conversation 关联）
            msg_row = await fetch_one(
                conn,
                """SELECT COUNT(*) as cnt FROM messages m
                   JOIN conversations c ON m.conversation_id = c.id
                   WHERE c.user_id = ?""",
                (user_id,),
            )
            # 积分消耗
            points_row = await fetch_one(
                conn,
                """SELECT COALESCE(SUM(ABS(points)), 0) as total
                   FROM points_log WHERE user_id = ? AND points < 0""",
                (user_id,),
            )
            # 活跃天数（去重日期）
            active_row = await fetch_one(
                conn,
                """SELECT COUNT(DISTINCT DATE(created_at)) as days
                   FROM analytics_events WHERE user_id = ?""",
                (user_id,),
            )
            # 写作数
            writing_row = await fetch_one(
                conn,
                "SELECT COUNT(*) as cnt FROM writing_tasks WHERE user_id = ?",
                (user_id,),
            )
            # 绘画数
            image_row = await fetch_one(
                conn,
                "SELECT COUNT(*) as cnt FROM image_tasks WHERE user_id = ?",
                (user_id,),
            )

        summary = {
            "total_conversations": conv_row["cnt"] if conv_row else 0,
            "total_messages": msg_row["cnt"] if msg_row else 0,
            "points_consumed": points_row["total"] if points_row else 0,
            "active_days": active_row["days"] if active_row else 0,
            "writing_count": writing_row["cnt"] if writing_row else 0,
            "image_count": image_row["cnt"] if image_row else 0,
            "period": "all",
        }

        self._cache_set(cache_key, summary)
        return summary

    async def get_trends(
        self,
        user_id: str,
        days: int = 7,
    ) -> List[Dict[str, Any]]:
        """
        获取趋势数据
        返回最近 N 天每天的对话数/消息数/积分消耗
        """
        cache_key = f"trends:{user_id}:{days}"
        cached = self._cache_get(cache_key)
        if cached:
            return cached

        end_date = datetime.now(timezone.utc).date()
        start_date = end_date - timedelta(days=days - 1)

        async with get_db_conn() as conn:
            # 按天统计对话数
            conv_trend = await fetch_all(
                conn,
                """SELECT DATE(created_at) as date, COUNT(*) as cnt
                   FROM conversations
                   WHERE user_id = ? AND DATE(created_at) >= ?
                   GROUP BY DATE(created_at) ORDER BY date""",
                (user_id, start_date.isoformat()),
            )
            conv_map = {r["date"]: r["cnt"] for r in conv_trend}

            # 按天统计消息数
            msg_trend = await fetch_all(
                conn,
                """SELECT DATE(m.created_at) as date, COUNT(*) as cnt
                   FROM messages m
                   JOIN conversations c ON m.conversation_id = c.id
                   WHERE c.user_id = ? AND DATE(m.created_at) >= ?
                   GROUP BY DATE(m.created_at) ORDER BY date""",
                (user_id, start_date.isoformat()),
            )
            msg_map = {r["date"]: r["cnt"] for r in msg_trend}

            # 按天统计积分
            points_trend = await fetch_all(
                conn,
                """SELECT DATE(created_at) as date, COALESCE(SUM(ABS(points)), 0) as total
                   FROM points_log
                   WHERE user_id = ? AND points < 0 AND DATE(created_at) >= ?
                   GROUP BY DATE(created_at) ORDER BY date""",
                (user_id, start_date.isoformat()),
            )
            points_map = {r["date"]: r["total"] for r in points_trend}

        # 补全所有日期
        result = []
        for i in range(days):
            d = (start_date + timedelta(days=i)).isoformat()
            result.append({
                "date": d,
                "conversations": conv_map.get(d, 0),
                "messages": msg_map.get(d, 0),
                "points": points_map.get(d, 0),
            })

        self._cache_set(cache_key, result)
        return result

    async def get_platform_stats(self) -> Dict[str, Any]:
        """平台级统计（管理员用）"""
        cache_key = "platform:stats"
        cached = self._cache_get(cache_key)
        if cached:
            return cached

        today = datetime.now(timezone.utc).date().isoformat()

        async with get_db_conn() as conn:
            total_users = await fetch_one(conn, "SELECT COUNT(*) as cnt FROM users")
            active_today = await fetch_one(
                conn,
                "SELECT COUNT(DISTINCT user_id) as cnt FROM analytics_events WHERE DATE(created_at) = ?",
                (today,),
            )
            total_messages = await fetch_one(conn, "SELECT COUNT(*) as cnt FROM messages")
            total_posts = await fetch_one(conn, "SELECT COUNT(*) as cnt FROM posts")
            pending_posts = await fetch_one(
                conn, "SELECT COUNT(*) as cnt FROM posts WHERE approved = 0"
            )
            total_convs = await fetch_one(conn, "SELECT COUNT(*) as cnt FROM conversations")
            banned = await fetch_one(
                conn, "SELECT COUNT(*) as cnt FROM users WHERE is_banned = 1"
            )
            total_feedback = await fetch_one(conn, "SELECT COUNT(*) as cnt FROM feedbacks")
            pending_feedback = await fetch_one(
                conn, "SELECT COUNT(*) as cnt FROM feedbacks WHERE status = 'pending'"
            )

        stats = {
            "total_users": total_users["cnt"] if total_users else 0,
            "active_users_today": active_today["cnt"] if active_today else 0,
            "total_messages": total_messages["cnt"] if total_messages else 0,
            "total_posts": total_posts["cnt"] if total_posts else 0,
            "pending_posts": pending_posts["cnt"] if pending_posts else 0,
            "total_conversations": total_convs["cnt"] if total_convs else 0,
            "banned_users": banned["cnt"] if banned else 0,
            "total_feedback": total_feedback["cnt"] if total_feedback else 0,
            "pending_feedback": pending_feedback["cnt"] if pending_feedback else 0,
        }

        self._cache_set(cache_key, stats)
        return stats


# 全局单例
analytics_service = AnalyticsService()
