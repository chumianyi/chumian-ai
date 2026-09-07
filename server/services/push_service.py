"""
推送服务 - PushService
功能：
- 推送消息构建
- 设备管理（注册/查询/禁用）
- 批量发送
- 推送历史
- 主题订阅
- 推送设置管理
"""
import uuid
import json
from typing import Dict, Any, Optional, List
from datetime import datetime, timezone

from database import get_db_conn, fetch_one, fetch_all, execute


# ===== 推送类型 =====
PUSH_TYPES = {
    "system": {"title_prefix": "[系统通知]", "priority": "high"},
    "message": {"title_prefix": "[新消息]", "priority": "normal"},
    "marketing": {"title_prefix": "[活动推荐]", "priority": "low"},
}


class PushService:
    """推送服务"""

    async def register_device(
        self,
        user_id: str,
        device_token: str,
        platform: str,
        device_model: Optional[str] = None,
    ) -> Dict[str, Any]:
        """
        注册推送设备
        同一 user_id + device_token 唯一，重复注册更新活跃时间
        """
        now = datetime.now(timezone.utc).isoformat()
        device_id = uuid.uuid4().hex

        async with get_db_conn() as conn:
            # 检查是否已存在
            existing = await fetch_one(
                conn,
                "SELECT id FROM push_devices WHERE user_id = ? AND device_token = ?",
                (user_id, device_token),
            )

            if existing:
                await execute(
                    conn,
                    "UPDATE push_devices SET last_active = ?, enabled = 1 WHERE id = ?",
                    (now, existing["id"]),
                )
                device_id = existing["id"]
            else:
                await execute(
                    conn,
                    """INSERT INTO push_devices
                       (id, user_id, device_token, platform, device_model, enabled, last_active, created_at)
                       VALUES (?, ?, ?, ?, ?, 1, ?, ?)""",
                    (device_id, user_id, device_token, platform, device_model, now, now),
                )

            # 确保推送设置记录存在
            settings_row = await fetch_one(
                conn, "SELECT user_id FROM push_settings WHERE user_id = ?", (user_id,)
            )
            if not settings_row:
                await execute(
                    conn,
                    """INSERT INTO push_settings
                       (user_id, enabled, message_push, system_push, marketing_push, updated_at)
                       VALUES (?, 1, 1, 1, 0, ?)""",
                    (user_id, now),
                )

        return {
            "device_id": device_id,
            "user_id": user_id,
            "platform": platform,
            "registered": True,
        }

    async def get_user_devices(self, user_id: str) -> List[Dict[str, Any]]:
        """获取用户的所有推送设备"""
        async with get_db_conn() as conn:
            devices = await fetch_all(
                conn,
                """SELECT id, platform, device_model, enabled, last_active, created_at
                   FROM push_devices WHERE user_id = ? ORDER BY last_active DESC""",
                (user_id,),
            )
        return devices

    async def get_settings(self, user_id: str) -> Dict[str, Any]:
        """获取用户推送设置"""
        async with get_db_conn() as conn:
            row = await fetch_one(
                conn,
                "SELECT * FROM push_settings WHERE user_id = ?",
                (user_id,),
            )

        if not row:
            return {
                "user_id": user_id,
                "enabled": True,
                "message_push": True,
                "system_push": True,
                "marketing_push": False,
            }

        return {
            "user_id": row["user_id"],
            "enabled": bool(row["enabled"]),
            "message_push": bool(row["message_push"]),
            "system_push": bool(row["system_push"]),
            "marketing_push": bool(row["marketing_push"]),
        }

    async def update_settings(
        self,
        user_id: str,
        enabled: Optional[bool] = None,
        message_push: Optional[bool] = None,
        system_push: Optional[bool] = None,
        marketing_push: Optional[bool] = None,
    ) -> Dict[str, Any]:
        """更新推送设置"""
        now = datetime.now(timezone.utc).isoformat()

        async with get_db_conn() as conn:
            existing = await fetch_one(
                conn, "SELECT * FROM push_settings WHERE user_id = ?", (user_id,)
            )

            if existing:
                updates = []
                params = []
                if enabled is not None:
                    updates.append("enabled = ?")
                    params.append(int(enabled))
                if message_push is not None:
                    updates.append("message_push = ?")
                    params.append(int(message_push))
                if system_push is not None:
                    updates.append("system_push = ?")
                    params.append(int(system_push))
                if marketing_push is not None:
                    updates.append("marketing_push = ?")
                    params.append(int(marketing_push))

                if updates:
                    updates.append("updated_at = ?")
                    params.append(now)
                    params.append(user_id)
                    await execute(
                        conn,
                        f"UPDATE push_settings SET {', '.join(updates)} WHERE user_id = ?",
                        tuple(params),
                    )
            else:
                await execute(
                    conn,
                    """INSERT INTO push_settings
                       (user_id, enabled, message_push, system_push, marketing_push, updated_at)
                       VALUES (?, ?, ?, ?, ?, ?)""",
                    (
                        user_id,
                        int(enabled if enabled is not None else True),
                        int(message_push if message_push is not None else True),
                        int(system_push if system_push is not None else True),
                        int(marketing_push if marketing_push is not None else False),
                        now,
                    ),
                )

        return await self.get_settings(user_id)

    async def send_push(
        self,
        user_id: Optional[str],
        title: str,
        body: str,
        push_type: str = "system",
    ) -> Dict[str, Any]:
        """
        发送推送
        user_id 为空时广播给所有启用设备
        返回发送结果统计
        """
        type_config = PUSH_TYPES.get(push_type, PUSH_TYPES["system"])
        full_title = f"{type_config['title_prefix']} {title}"

        async with get_db_conn() as conn:
            if user_id:
                # 检查用户推送设置
                settings = await fetch_one(
                    conn, "SELECT * FROM push_settings WHERE user_id = ?", (user_id,)
                )
                if settings and not settings["enabled"]:
                    return {"sent": 0, "skipped": 1, "reason": "用户已关闭推送"}

                # 检查具体类型开关
                type_col = f"{push_type}_push"
                if settings and type_col in settings.keys() and not settings[type_col]:
                    return {"sent": 0, "skipped": 1, "reason": f"用户已关闭{push_type}推送"}

                devices = await fetch_all(
                    conn,
                    """SELECT device_token, platform FROM push_devices
                       WHERE user_id = ? AND enabled = 1""",
                    (user_id,),
                )
            else:
                # 广播：只发给开启了对应类型推送的用户
                devices = await fetch_all(
                    conn,
                    f"""SELECT d.device_token, d.platform, d.user_id
                        FROM push_devices d
                        JOIN push_settings s ON d.user_id = s.user_id
                        WHERE d.enabled = 1 AND s.enabled = 1
                          AND s.{type_col if (type_col := f'{push_type}_push') else 'system_push'} = 1""",
                )

        # 实际发送：记录日志，调用上游推送服务
        sent_count = 0
        for device in devices:
            success = await self._dispatch_to_provider(
                device["device_token"],
                device["platform"],
                full_title,
                body,
                push_type,
            )
            if success:
                sent_count += 1

        return {
            "sent": sent_count,
            "total": len(devices),
            "skipped": len(devices) - sent_count,
            "push_type": push_type,
        }

    async def _dispatch_to_provider(
        self,
        device_token: str,
        platform: str,
        title: str,
        body: str,
        push_type: str,
    ) -> bool:
        """
        实际调用推送服务商（FCM/APNs/极光等）
        当前为占位实现，返回 True
        生产环境应替换为真实 SDK 调用
        """
        # 推送延迟
        import asyncio
        await asyncio.sleep(0.01)
        # 实际项目中：
        # if platform == "android": 调用 FCM / 极光
        # elif platform == "ios": 调用 APNs
        # elif platform == "web": 调用 Web Push
        return True

    async def get_push_history(
        self,
        user_id: str,
        page: int = 1,
        page_size: int = 20,
    ) -> Dict[str, Any]:
        """获取推送历史（通过 notifications 表关联）"""
        offset = (page - 1) * page_size

        async with get_db_conn() as conn:
            rows = await fetch_all(
                conn,
                """SELECT * FROM notifications
                   WHERE user_id = ? ORDER BY created_at DESC LIMIT ? OFFSET ?""",
                (user_id, page_size, offset),
            )
            total_row = await fetch_one(
                conn,
                "SELECT COUNT(*) as cnt FROM notifications WHERE user_id = ?",
                (user_id,),
            )

        return {
            "items": rows,
            "total": total_row["cnt"] if total_row else 0,
            "page": page,
            "page_size": page_size,
        }


# 全局单例
push_service = PushService()
