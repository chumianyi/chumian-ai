"""
成就服务 - AchievementService
功能：
- 成就定义管理
- 进度计算
- 解锁检测
- 奖励发放（积分/钻石）
- 成就等级
"""
import uuid
from typing import Dict, Any, Optional, List
from datetime import datetime, timezone

from database import get_db_conn, fetch_one, fetch_all, execute


class AchievementService:
    """成就服务"""

    async def get_all_achievements(self) -> List[Dict[str, Any]]:
        """获取所有成就定义"""
        async with get_db_conn() as conn:
            rows = await fetch_all(
                conn,
                "SELECT * FROM achievements ORDER BY category, target_value",
            )
        return rows

    async def get_user_achievements(self, user_id: str) -> List[Dict[str, Any]]:
        """
        获取用户成就状态（全部成就 + 个人进度）
        """
        async with get_db_conn() as conn:
            # 获取所有成就定义
            achievements = await fetch_all(
                conn, "SELECT * FROM achievements ORDER BY category, target_value"
            )
            # 获取用户成就进度
            user_achs = await fetch_all(
                conn,
                "SELECT * FROM user_achievements WHERE user_id = ?",
                (user_id,),
            )

        user_map = {ua["achievement_id"]: ua for ua in user_achs}

        result = []
        for ach in achievements:
            ua = user_map.get(ach["id"], {})
            current = ua.get("current_value", 0)
            target = ach["target_value"]
            progress = min(current / target, 1.0) if target > 0 else 0.0

            result.append({
                "achievement_id": ach["id"],
                "name": ach["name"],
                "description": ach["description"],
                "icon": ach.get("icon"),
                "category": ach["category"],
                "progress": round(progress, 4),
                "current_value": current,
                "target_value": target,
                "unlocked": bool(ua.get("unlocked", 0)),
                "claimed": bool(ua.get("claimed", 0)),
                "reward_points": ach["reward_points"],
                "reward_diamonds": ach["reward_diamonds"],
                "unlocked_at": ua.get("unlocked_at"),
            })

        return result

    async def update_progress(
        self,
        user_id: str,
        achievement_id: str,
        increment: int = 1,
    ) -> Optional[Dict[str, Any]]:
        """
        更新成就进度
        如果达到目标值，自动解锁
        返回解锁信息（如果新解锁）
        """
        now = datetime.now(timezone.utc).isoformat()

        async with get_db_conn() as conn:
            ach = await fetch_one(
                conn, "SELECT * FROM achievements WHERE id = ?", (achievement_id,)
            )
            if not ach:
                return None

            # 获取或创建用户成就记录
            ua = await fetch_one(
                conn,
                "SELECT * FROM user_achievements WHERE user_id = ? AND achievement_id = ?",
                (user_id, achievement_id),
            )

            if not ua:
                ua_id = uuid.uuid4().hex
                new_value = increment
                await execute(
                    conn,
                    """INSERT INTO user_achievements
                       (id, user_id, achievement_id, current_value, unlocked, claimed)
                       VALUES (?, ?, ?, ?, 0, 0)""",
                    (ua_id, user_id, achievement_id, new_value),
                )
            else:
                new_value = ua["current_value"] + increment
                await execute(
                    conn,
                    "UPDATE user_achievements SET current_value = ? WHERE id = ?",
                    (new_value, ua["id"]),
                )

            # 检查是否解锁
            unlocked_info = None
            if new_value >= ach["target_value"] and not (ua and ua["unlocked"]):
                await execute(
                    conn,
                    """UPDATE user_achievements
                       SET unlocked = 1, unlocked_at = ?
                       WHERE user_id = ? AND achievement_id = ?""",
                    (now, user_id, achievement_id),
                )
                unlocked_info = {
                    "achievement_id": ach["id"],
                    "name": ach["name"],
                    "reward_points": ach["reward_points"],
                    "reward_diamonds": ach["reward_diamonds"],
                }

        return unlocked_info

    async def claim_reward(
        self,
        user_id: str,
        achievement_id: str,
    ) -> Dict[str, Any]:
        """
        领取成就奖励
        发放积分和钻石到用户账户
        """
        now = datetime.now(timezone.utc).isoformat()

        async with get_db_conn() as conn:
            ua = await fetch_one(
                conn,
                "SELECT * FROM user_achievements WHERE user_id = ? AND achievement_id = ?",
                (user_id, achievement_id),
            )
            if not ua:
                return {"success": False, "error": "成就记录不存在"}
            if not ua["unlocked"]:
                return {"success": False, "error": "成就尚未解锁"}
            if ua["claimed"]:
                return {"success": False, "error": "奖励已领取"}

            ach = await fetch_one(
                conn, "SELECT * FROM achievements WHERE id = ?", (achievement_id,)
            )
            if not ach:
                return {"success": False, "error": "成就定义不存在"}

            # 标记已领取
            await execute(
                conn,
                "UPDATE user_achievements SET claimed = 1, claimed_at = ? WHERE id = ?",
                (now, ua["id"]),
            )

            # 发放积分
            reward_points = ach["reward_points"]
            if reward_points > 0:
                user = await fetch_one(
                    conn, "SELECT daily_points FROM users WHERE id = ?", (user_id,)
                )
                new_points = (user["daily_points"] if user else 0) + reward_points
                await execute(
                    conn,
                    "UPDATE users SET daily_points = ? WHERE id = ?",
                    (new_points, user_id),
                )
                # 记录积分流水
                log_id = uuid.uuid4().hex
                await execute(
                    conn,
                    """INSERT INTO points_log (id, user_id, points, reason, created_at)
                       VALUES (?, ?, ?, ?, ?)""",
                    (log_id, user_id, reward_points, f"成就奖励: {ach['name']}", now),
                )

            # 发放钻石
            reward_diamonds = ach["reward_diamonds"]
            if reward_diamonds > 0:
                user = await fetch_one(
                    conn, "SELECT diamonds FROM users WHERE id = ?", (user_id,)
                )
                new_diamonds = (user["diamonds"] if user else 0) + reward_diamonds
                await execute(
                    conn,
                    "UPDATE users SET diamonds = ? WHERE id = ?",
                    (new_diamonds, user_id),
                )

            # 记录钱包交易
            tx_id = uuid.uuid4().hex
            await execute(
                conn,
                """INSERT INTO wallet_transactions
                   (id, user_id, type, amount, currency, description, balance_after, created_at)
                   VALUES (?, ?, 'achievement', ?, 'points', ?, ?, ?)""",
                (tx_id, user_id, reward_points, f"成就奖励: {ach['name']}", new_points, now),
            )

        return {
            "success": True,
            "achievement_id": achievement_id,
            "name": ach["name"],
            "reward_points": reward_points,
            "reward_diamonds": reward_diamonds,
        }

    async def check_and_unlock(self, user_id: str) -> List[Dict[str, Any]]:
        """
        检查所有成就，自动更新进度并解锁
        基于用户实际数据计算进度
        返回新解锁的成就列表
        """
        newly_unlocked = []

        async with get_db_conn() as conn:
            achievements = await fetch_all(conn, "SELECT * FROM achievements")

            # 预计算用户各项数据
            stats = await self._compute_user_stats(conn, user_id)

            for ach in achievements:
                current = self._get_achievement_current(ach["id"], stats)
                if current <= 0:
                    continue

                ua = await fetch_one(
                    conn,
                    "SELECT * FROM user_achievements WHERE user_id = ? AND achievement_id = ?",
                    (user_id, ach["id"]),
                )

                if not ua:
                    ua_id = uuid.uuid4().hex
                    await execute(
                        conn,
                        """INSERT INTO user_achievements
                           (id, user_id, achievement_id, current_value, unlocked, claimed)
                           VALUES (?, ?, ?, ?, 0, 0)""",
                        (ua_id, user_id, ach["id"], current),
                    )
                elif ua["current_value"] != current:
                    await execute(
                        conn,
                        "UPDATE user_achievements SET current_value = ? WHERE id = ?",
                        (current, ua["id"]),
                    )

                # 检查解锁
                if current >= ach["target_value"] and not (ua and ua["unlocked"]):
                    now = datetime.now(timezone.utc).isoformat()
                    await execute(
                        conn,
                        """UPDATE user_achievements
                           SET unlocked = 1, unlocked_at = ?
                           WHERE user_id = ? AND achievement_id = ?""",
                        (now, user_id, ach["id"]),
                    )
                    newly_unlocked.append({
                        "achievement_id": ach["id"],
                        "name": ach["name"],
                        "description": ach["description"],
                        "icon": ach.get("icon"),
                        "reward_points": ach["reward_points"],
                        "reward_diamonds": ach["reward_diamonds"],
                    })

        return newly_unlocked

    async def _compute_user_stats(self, conn, user_id: str) -> Dict[str, int]:
        """计算用户各项统计数据"""
        stats = {}

        # 对话数
        row = await fetch_one(
            conn, "SELECT COUNT(*) as cnt FROM conversations WHERE user_id = ?", (user_id,)
        )
        stats["conversations"] = row["cnt"] if row else 0

        # 帖子数
        row = await fetch_one(
            conn, "SELECT COUNT(*) as cnt FROM posts WHERE user_id = ?", (user_id,)
        )
        stats["posts"] = row["cnt"] if row else 0

        # 获赞数
        row = await fetch_one(
            conn,
            """SELECT COALESCE(SUM(p.likes), 0) as total FROM posts p WHERE p.user_id = ?""",
            (user_id,),
        )
        stats["post_likes"] = row["total"] if row else 0

        # 写作数
        row = await fetch_one(
            conn, "SELECT COUNT(*) as cnt FROM writing_tasks WHERE user_id = ? AND status = 'completed'", (user_id,)
        )
        stats["writing_count"] = row["cnt"] if row else 0

        # 绘画数
        row = await fetch_one(
            conn, "SELECT COUNT(*) as cnt FROM image_tasks WHERE user_id = ? AND status = 'completed'", (user_id,)
        )
        stats["image_count"] = row["cnt"] if row else 0

        # 签到天数（最大连续）
        row = await fetch_one(
            conn,
            "SELECT MAX(streak) as max_streak FROM checkins WHERE user_id = ?",
            (user_id,),
        )
        stats["max_checkin_streak"] = row["max_streak"] if row and row["max_streak"] else 0

        # 好友数
        row = await fetch_one(
            conn, "SELECT COUNT(*) as cnt FROM friends WHERE user_id = ?", (user_id,)
        )
        stats["friends_count"] = row["cnt"] if row else 0

        # 积分余额
        row = await fetch_one(
            conn, "SELECT daily_points FROM users WHERE id = ?", (user_id,)
        )
        stats["points_balance"] = row["daily_points"] if row else 0

        return stats

    def _get_achievement_current(self, achievement_id: str, stats: Dict[str, int]) -> int:
        """根据成就 ID 获取对应用户数据"""
        mapping = {
            "first_message": stats.get("conversations", 0),
            "chat_master": stats.get("conversations", 0),
            "first_post": stats.get("posts", 0),
            "popular_writer": stats.get("post_likes", 0),
            "first_writing": stats.get("writing_count", 0),
            "writing_pro": stats.get("writing_count", 0),
            "first_image": stats.get("image_count", 0),
            "artist": stats.get("image_count", 0),
            "checkin_7": stats.get("max_checkin_streak", 0),
            "checkin_30": stats.get("max_checkin_streak", 0),
            "friend_maker": stats.get("friends_count", 0),
            "rich": stats.get("points_balance", 0),
        }
        return mapping.get(achievement_id, 0)


# 全局单例
achievement_service = AchievementService()
