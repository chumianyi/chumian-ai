"""
AI 绘画服务 - ImageGenService
功能：
- 绘画任务管理（创建/查询/历史/删除）
- 上游 API 调用（智谱 CogView）
- 轮询机制
- 结果存储（本地保存 + URL 返回）
- 风格预设
- 尺寸校验
未配置 ZHIPU_API_KEY 时任务失败，绝不返回模拟图片
"""
import uuid
import os
import httpx
from typing import Dict, Any, Optional, List
from datetime import datetime, timezone

from config import settings
from database import get_db_conn, fetch_one, fetch_all, execute
from services.task_queue import TaskQueue, TaskStatus


# ===== 风格预设 =====
STYLE_PRESETS = {
    "写实": "photorealistic, high detail, 8k, professional photography",
    "动漫": "anime style, cel shading, vibrant colors, manga art",
    "油画": "oil painting style, brush strokes, classical art, textured",
    "水彩": "watercolor painting, soft colors, artistic, flowing",
    "赛博朋克": "cyberpunk style, neon lights, futuristic, high tech, dystopian",
}

VALID_STYLES = list(STYLE_PRESETS.keys())

# ===== 支持的尺寸 =====
VALID_SIZES = ["512x512", "768x768", "1024x1024"]


class ImageGenService:
    """AI 绘画服务"""

    def __init__(self):
        self.queue = TaskQueue.get_instance()
        self.queue.register_handler("image_gen", self._process_task)

    def validate_request(
        self, prompt: str, style: str, size: str
    ) -> Optional[str]:
        """校验绘画请求"""
        if not prompt or not prompt.strip():
            return "提示词不能为空"
        if len(prompt) > 1000:
            return "提示词长度不能超过 1000 字"
        if style not in VALID_STYLES:
            return f"不支持的风格: {style}，支持: {', '.join(VALID_STYLES)}"
        if size not in VALID_SIZES:
            return f"不支持的尺寸: {size}，支持: {', '.join(VALID_SIZES)}"
        return None

    def build_full_prompt(self, prompt: str, style: str) -> str:
        """构造完整提示词（追加风格后缀）"""
        style_suffix = STYLE_PRESETS.get(style, "")
        if style_suffix:
            return f"{prompt}, {style_suffix}"
        return prompt

    async def create_task(
        self,
        user_id: str,
        prompt: str,
        style: str = "写实",
        size: str = "1024x1024",
        negative_prompt: Optional[str] = None,
    ) -> Dict[str, Any]:
        """创建绘画任务"""
        task_id = uuid.uuid4().hex
        now = datetime.now(timezone.utc).isoformat()

        async with get_db_conn() as conn:
            await execute(
                conn,
                """INSERT INTO image_tasks
                   (id, user_id, prompt, style, size, negative_prompt, status, created_at)
                   VALUES (?, ?, ?, ?, ?, ?, 'pending', ?)""",
                (task_id, user_id, prompt, style, size, negative_prompt, now),
            )

        # 提交到异步队列
        await self.queue.submit(
            "image_gen",
            {
                "task_id": task_id,
                "user_id": user_id,
                "prompt": prompt,
                "style": style,
                "size": size,
                "negative_prompt": negative_prompt,
            },
            max_retries=2,
            timeout=120.0,
        )

        return {
            "task_id": task_id,
            "prompt": prompt,
            "style": style,
            "size": size,
            "status": "pending",
            "created_at": now,
        }

    async def get_task(self, task_id: str, user_id: str) -> Optional[Dict[str, Any]]:
        """查询任务状态"""
        mem_task = await self.queue.get_task(task_id)
        if mem_task:
            if mem_task.status == TaskStatus.COMPLETED:
                await self._save_result(task_id, mem_task.result, None)
            elif mem_task.status == TaskStatus.FAILED:
                await self._save_result(task_id, None, mem_task.error)

        async with get_db_conn() as conn:
            task = await fetch_one(
                conn,
                "SELECT * FROM image_tasks WHERE id = ? AND user_id = ?",
                (task_id, user_id),
            )
        return task

    async def get_history(
        self,
        user_id: str,
        page: int = 1,
        page_size: int = 20,
    ) -> Dict[str, Any]:
        """获取绘画历史"""
        offset = (page - 1) * page_size

        async with get_db_conn() as conn:
            rows = await fetch_all(
                conn,
                """SELECT id, prompt, style, size, status, image_url, created_at
                   FROM image_tasks WHERE user_id = ?
                   ORDER BY created_at DESC LIMIT ? OFFSET ?""",
                (user_id, page_size, offset),
            )
            total_row = await fetch_one(
                conn,
                "SELECT COUNT(*) as cnt FROM image_tasks WHERE user_id = ?",
                (user_id,),
            )

        return {
            "items": rows,
            "total": total_row["cnt"] if total_row else 0,
            "page": page,
            "page_size": page_size,
        }

    async def delete_task(self, task_id: str, user_id: str) -> bool:
        """删除绘画记录"""
        async with get_db_conn() as conn:
            task = await fetch_one(
                conn,
                "SELECT id FROM image_tasks WHERE id = ? AND user_id = ?",
                (task_id, user_id),
            )
            if not task:
                return False
            await execute(conn, "DELETE FROM image_tasks WHERE id = ?", (task_id,))
        return True

    async def _process_task(self, payload: Dict[str, Any]) -> str:
        """
        任务队列处理器：调用上游图片生成 API
        未配置 ZHIPU_API_KEY 时抛出异常
        """
        if not settings.ZHIPU_API_KEY:
            raise RuntimeError("未配置模型密钥，请在服务端配置 ZHIPU_API_KEY 环境变量")

        prompt = payload["prompt"]
        style = payload["style"]
        size = payload["size"]

        full_prompt = self.build_full_prompt(prompt, style)
        return await self._call_zhipu_api(full_prompt, size)

    async def _call_zhipu_api(self, prompt: str, size: str) -> str:
        """调用智谱 CogView 文生图 API"""
        url = f"{settings.ZHIPU_BASE_URL}/images/generations"
        headers = {
            "Authorization": f"Bearer {settings.ZHIPU_API_KEY}",
            "Content-Type": "application/json",
        }

        payload = {
            "model": "cogview-3-flash",
            "prompt": prompt,
            "size": size,
        }

        async with httpx.AsyncClient(timeout=120.0) as client:
            response = await client.post(url, headers=headers, json=payload)
            if response.status_code != 200:
                raise ValueError(
                    f"上游 API 错误 {response.status_code}: {response.text}"
                )
            data = response.json()
            image_url = data.get("data", [{}])[0].get("url", "")
            if not image_url:
                raise ValueError("上游 API 未返回图片 URL")

            # 下载图片到本地 media 目录
            local_url = await self._download_image(image_url)
            return local_url

    async def _download_image(self, url: str) -> str:
        """下载图片到本地 media 目录，返回可访问的 URL"""
        os.makedirs(settings.MEDIA_DIR, exist_ok=True)
        filename = f"gen_{uuid.uuid4().hex[:12]}.png"
        filepath = os.path.join(settings.MEDIA_DIR, filename)

        async with httpx.AsyncClient(timeout=60.0, follow_redirects=True) as client:
            response = await client.get(url)
            if response.status_code == 200:
                with open(filepath, "wb") as f:
                    f.write(response.content)
                return f"/media/{filename}"

        return url

    async def _save_result(
        self,
        task_id: str,
        result: Optional[str],
        error: Optional[str],
    ):
        """保存结果到数据库"""
        now = datetime.now(timezone.utc).isoformat()
        status = "completed" if result else "failed"

        async with get_db_conn() as conn:
            await execute(
                conn,
                """UPDATE image_tasks
                   SET status = ?, image_url = ?, error = ?, completed_at = ?
                   WHERE id = ?""",
                (status, result, error, now, task_id),
            )


# 全局单例
image_gen_service = ImageGenService()
