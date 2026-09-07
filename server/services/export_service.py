"""
导出服务 - ExportService
功能：
- 聊天记录导出：支持 TXT/Markdown/JSON 格式
- 格式转换：消息格式化、时间戳处理
- 文件生成：异步生成导出文件
- 下载管理：文件存储、下载链接、过期清理
"""
import os
import json
import uuid
import asyncio
from typing import Dict, Any, Optional, List
from datetime import datetime, timezone, timedelta

from config import settings
from database import get_db_conn, fetch_one, fetch_all, execute


# 支持的导出格式
SUPPORTED_FORMATS = ["txt", "md", "json"]

# 导出文件过期时间（小时）
EXPORT_EXPIRY_HOURS = 24


class ExportService:
    """聊天记录导出服务"""

    def __init__(self):
        self.export_dir = os.path.join(settings.MEDIA_DIR, "exports")
        os.makedirs(self.export_dir, exist_ok=True)

    # ==========================================================================
    # 创建导出任务
    # ==========================================================================

    async def create_export(
        self,
        user_id: str,
        conversation_id: str,
        export_format: str = "md",
        include_metadata: bool = True,
    ) -> Dict[str, Any]:
        """
        创建聊天记录导出任务
        异步生成导出文件
        """
        if export_format not in SUPPORTED_FORMATS:
            raise ValueError(f"不支持的导出格式: {export_format}，支持: {', '.join(SUPPORTED_FORMATS)}")

        # 验证会话归属
        async with get_db_conn() as conn:
            conv = await fetch_one(
                conn,
                "SELECT id, title, user_id, created_at FROM conversations WHERE id = ? AND user_id = ?",
                (conversation_id, user_id),
            )

        if not conv:
            raise ValueError("会话不存在或无权访问")

        task_id = uuid.uuid4().hex
        now = datetime.now(timezone.utc).isoformat()

        # 创建任务记录
        async with get_db_conn() as conn:
            await execute(
                conn,
                """INSERT INTO export_tasks
                   (id, user_id, conversation_id, format, include_metadata,
                    status, created_at)
                   VALUES (?, ?, ?, ?, ?, 'processing', ?)""",
                (task_id, user_id, conversation_id, export_format,
                 1 if include_metadata else 0, now),
            )

        # 异步生成文件
        asyncio.create_task(self._generate_export(
            task_id=task_id,
            user_id=user_id,
            conversation=conv,
            export_format=export_format,
            include_metadata=include_metadata,
        ))

        return {
            "task_id": task_id,
            "conversation_id": conversation_id,
            "format": export_format,
            "status": "processing",
            "created_at": now,
        }

    # ==========================================================================
    # 查询导出状态
    # ==========================================================================

    async def get_task(self, task_id: str, user_id: str) -> Optional[Dict[str, Any]]:
        """查询导出任务状态"""
        async with get_db_conn() as conn:
            task = await fetch_one(
                conn,
                """SELECT id, user_id, conversation_id, format, include_metadata,
                           file_url, file_size, message_count, status, error,
                           created_at, completed_at
                    FROM export_tasks
                    WHERE id = ? AND user_id = ?""",
                (task_id, user_id),
            )
        return task

    # ==========================================================================
    # 下载文件
    # ==========================================================================

    async def get_download_file(
        self,
        file_id: str,
        user_id: str,
    ) -> Optional[Dict[str, Any]]:
        """
        获取导出文件下载信息
        检查文件是否存在、是否过期、是否有权限
        """
        async with get_db_conn() as conn:
            task = await fetch_one(
                conn,
                """SELECT id, user_id, file_url, file_size, format,
                           status, completed_at
                    FROM export_tasks
                    WHERE id = ? AND user_id = ? AND status = 'completed'""",
                (file_id, user_id),
            )

        if not task:
            return None

        # 检查文件是否过期
        if task["completed_at"]:
            completed = datetime.fromisoformat(task["completed_at"].replace("Z", "+00:00"))
            if datetime.now(timezone.utc) - completed > timedelta(hours=EXPORT_EXPIRY_HOURS):
                return {"expired": True, "task_id": file_id}

        # 检查文件是否存在
        filename = os.path.basename(task["file_url"])
        filepath = os.path.join(self.export_dir, filename)
        if not os.path.exists(filepath):
            return None

        return {
            "file_path": filepath,
            "file_url": task["file_url"],
            "file_size": task["file_size"],
            "format": task["format"],
            "filename": filename,
        }

    # ==========================================================================
    # 导出历史
    # ==========================================================================

    async def get_history(
        self,
        user_id: str,
        page: int = 1,
        page_size: int = 20,
    ) -> Dict[str, Any]:
        """获取导出历史列表"""
        offset = (page - 1) * page_size

        async with get_db_conn() as conn:
            rows = await fetch_all(
                conn,
                """SELECT id, conversation_id, format, file_url, file_size,
                           message_count, status, created_at, completed_at
                    FROM export_tasks
                    WHERE user_id = ?
                    ORDER BY created_at DESC LIMIT ? OFFSET ?""",
                (user_id, page_size, offset),
            )
            total_row = await fetch_one(
                conn,
                "SELECT COUNT(*) as cnt FROM export_tasks WHERE user_id = ?",
                (user_id,),
            )

        return {
            "items": rows,
            "total": total_row["cnt"] if total_row else 0,
            "page": page,
            "page_size": page_size,
        }

    # ==========================================================================
    # 清理过期文件
    # ==========================================================================

    async def cleanup_expired(self) -> int:
        """清理过期的导出文件，返回清理数量"""
        cutoff = (datetime.now(timezone.utc) - timedelta(hours=EXPORT_EXPIRY_HOURS)).isoformat()
        count = 0

        async with get_db_conn() as conn:
            expired = await fetch_all(
                conn,
                "SELECT id, file_url FROM export_tasks WHERE completed_at < ? AND status = 'completed'",
                (cutoff,),
            )

            for task in expired:
                if task["file_url"]:
                    filename = os.path.basename(task["file_url"])
                    filepath = os.path.join(self.export_dir, filename)
                    if os.path.exists(filepath):
                        os.remove(filepath)
                        count += 1

                await execute(
                    conn,
                    "UPDATE export_tasks SET status = 'expired', file_url = NULL WHERE id = ?",
                    (task["id"],),
                )

        return count

    # ==========================================================================
    # 内部：生成导出文件
    # ==========================================================================

    async def _generate_export(
        self,
        task_id: str,
        user_id: str,
        conversation: Dict[str, Any],
        export_format: str,
        include_metadata: bool,
    ):
        """异步生成导出文件"""
        try:
            # 获取会话消息
            async with get_db_conn() as conn:
                messages = await fetch_all(
                    conn,
                    """SELECT id, role, content, model, tokens_used, created_at
                       FROM messages
                       WHERE conversation_id = ?
                       ORDER BY created_at ASC""",
                    (conversation["id"],),
                )

            # 格式化内容
            if export_format == "txt":
                content = self._format_txt(messages, conversation, include_metadata)
            elif export_format == "md":
                content = self._format_md(messages, conversation, include_metadata)
            else:  # json
                content = self._format_json(messages, conversation, include_metadata)

            # 写入文件
            filename = f"export_{task_id}.{export_format}"
            filepath = os.path.join(self.export_dir, filename)
            with open(filepath, "w", encoding="utf-8") as f:
                f.write(content)

            file_size = os.path.getsize(filepath)
            file_url = f"/media/exports/{filename}"
            now = datetime.now(timezone.utc).isoformat()

            async with get_db_conn() as conn:
                await execute(
                    conn,
                    """UPDATE export_tasks
                       SET status = 'completed', file_url = ?, file_size = ?,
                           message_count = ?, completed_at = ?
                       WHERE id = ?""",
                    (file_url, file_size, len(messages), now, task_id),
                )

        except Exception as e:
            now = datetime.now(timezone.utc).isoformat()
            async with get_db_conn() as conn:
                await execute(
                    conn,
                    """UPDATE export_tasks
                       SET status = 'failed', error = ?, completed_at = ?
                       WHERE id = ?""",
                    (str(e), now, task_id),
                )

    # ==========================================================================
    # 格式化方法
    # ==========================================================================

    def _format_txt(
        self,
        messages: List[Dict[str, Any]],
        conversation: Dict[str, Any],
        include_metadata: bool,
    ) -> str:
        """格式化为纯文本"""
        lines = []
        lines.append("=" * 60)
        lines.append(f"  聊天记录导出")
        lines.append(f"  会话标题: {conversation.get('title', '未命名')}")
        lines.append(f"  导出时间: {datetime.now(timezone.utc).strftime('%Y-%m-%d %H:%M:%S')}")
        lines.append(f"  消息总数: {len(messages)}")
        lines.append("=" * 60)
        lines.append("")

        for msg in messages:
            role = "用户" if msg["role"] == "user" else "AI助手"
            timestamp = msg.get("created_at", "")
            try:
                dt = datetime.fromisoformat(timestamp.replace("Z", "+00:00"))
                time_str = dt.strftime("%Y-%m-%d %H:%M:%S")
            except (ValueError, AttributeError):
                time_str = timestamp

            lines.append(f"【{role}】 {time_str}")
            if include_metadata and msg.get("model"):
                lines.append(f"模型: {msg['model']}")
            if include_metadata and msg.get("tokens_used"):
                lines.append(f"Token: {msg['tokens_used']}")
            lines.append(msg.get("content", ""))
            lines.append("")
            lines.append("-" * 40)
            lines.append("")

        return "\n".join(lines)

    def _format_md(
        self,
        messages: List[Dict[str, Any]],
        conversation: Dict[str, Any],
        include_metadata: bool,
    ) -> str:
        """格式化为 Markdown"""
        lines = []
        lines.append(f"# {conversation.get('title', '聊天记录')}")
        lines.append("")
        lines.append(f"> 导出时间: {datetime.now(timezone.utc).strftime('%Y-%m-%d %H:%M:%S')}  ")
        lines.append(f"> 消息总数: {len(messages)}")
        lines.append("")
        lines.append("---")
        lines.append("")

        for msg in messages:
            role_icon = "🧑 用户" if msg["role"] == "user" else "🤖 AI助手"
            timestamp = msg.get("created_at", "")
            try:
                dt = datetime.fromisoformat(timestamp.replace("Z", "+00:00"))
                time_str = dt.strftime("%Y-%m-%d %H:%M:%S")
            except (ValueError, AttributeError):
                time_str = timestamp

            lines.append(f"### {role_icon}")
            lines.append("")
            lines.append(f"*{time_str}*")
            if include_metadata and msg.get("model"):
                lines.append(f"  \n*模型: `{msg['model']}`*")
            lines.append("")
            lines.append(msg.get("content", ""))
            lines.append("")
            lines.append("---")
            lines.append("")

        return "\n".join(lines)

    def _format_json(
        self,
        messages: List[Dict[str, Any]],
        conversation: Dict[str, Any],
        include_metadata: bool,
    ) -> str:
        """格式化为 JSON"""
        data = {
            "title": conversation.get("title", "聊天记录"),
            "conversation_id": conversation["id"],
            "exported_at": datetime.now(timezone.utc).isoformat(),
            "message_count": len(messages),
            "messages": [],
        }

        for msg in messages:
            entry = {
                "role": msg["role"],
                "content": msg.get("content", ""),
                "timestamp": msg.get("created_at", ""),
            }
            if include_metadata:
                if msg.get("model"):
                    entry["model"] = msg["model"]
                if msg.get("tokens_used"):
                    entry["tokens_used"] = msg["tokens_used"]
            data["messages"].append(entry)

        return json.dumps(data, ensure_ascii=False, indent=2)


# 全局单例
export_service = ExportService()
