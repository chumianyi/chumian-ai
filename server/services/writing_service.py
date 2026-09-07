"""
AI 写作服务 - WritingService
功能：
- 写作任务管理（创建/查询/历史/删除）
- LLM 调用生成内容
- 模板系统（按类型构造 prompt）
- 参数校验
- 结果格式化
- 异步任务队列集成
"""
import uuid
import json
from typing import Dict, Any, Optional, List
from datetime import datetime, timezone

from database import get_db_conn, fetch_one, fetch_all, execute
from services.task_queue import TaskQueue, TaskStatus


# ===== 写作类型配置 =====
WRITING_TYPES = {
    "作文": {
        "model": "glm-4-flash",
        "default_words": 800,
        "system_prompt": "你是一位资深语文老师，擅长写各类作文。要求结构清晰、语言优美、立意深刻。",
    },
    "论文": {
        "model": "glm-4-flash",
        "default_words": 3000,
        "system_prompt": "你是一位学术论文写作专家。要求论点明确、论据充分、逻辑严密、引用规范。",
    },
    "小说": {
        "model": "glm-4-flash",
        "default_words": 1500,
        "system_prompt": "你是一位小说家。要求情节生动、人物鲜明、描写细腻、引人入胜。",
    },
    "文案": {
        "model": "glm-4-flash",
        "default_words": 300,
        "system_prompt": "你是一位广告文案大师。要求简洁有力、卖点突出、有感染力、适合传播。",
    },
    "诗歌": {
        "model": "glm-4-flash",
        "default_words": 200,
        "system_prompt": "你是一位诗人。要求意境优美、韵律和谐、情感真挚、语言精炼。",
    },
    "总结": {
        "model": "glm-4-flash",
        "default_words": 500,
        "system_prompt": "你是一位总结归纳专家。要求条理清晰、重点突出、简明扼要。",
    },
    "翻译": {
        "model": "glm-4-flash",
        "default_words": 1000,
        "system_prompt": "你是一位专业翻译。要求准确传达原意、语言流畅、符合目标语言表达习惯。",
    },
}

VALID_TYPES = list(WRITING_TYPES.keys())


class WritingService:
    """AI 写作服务"""

    def __init__(self):
        self.queue = TaskQueue.get_instance()
        self.queue.register_handler("writing", self._process_task)

    def validate_request(self, writing_type: str, topic: str) -> Optional[str]:
        """校验写作请求，返回错误信息（None 表示通过）"""
        if writing_type not in VALID_TYPES:
            return f"不支持的写作类型: {writing_type}，支持: {', '.join(VALID_TYPES)}"
        if not topic or not topic.strip():
            return "主题不能为空"
        if len(topic) > 500:
            return "主题长度不能超过 500 字"
        return None

    def build_prompt(self, writing_type: str, topic: str, params: Dict[str, Any]) -> str:
        """根据类型和参数构造生成 prompt"""
        config = WRITING_TYPES[writing_type]
        word_count = params.get("word_count", config["default_words"])
        style = params.get("style", "")
        language = params.get("language", "中文")

        parts = [
            f"请以{language}撰写一篇{writing_type}。",
            f"主题：{topic}",
            f"字数要求：约 {word_count} 字",
        ]
        if style:
            parts.append(f"风格：{style}")
        if writing_type == "翻译":
            target = params.get("target_language", "英文")
            parts.append(f"目标语言：{target}")
            parts.append("请将以下内容翻译为目标语言，保持原意和语气。")
        if writing_type == "总结":
            parts.append("请对以下内容进行结构化总结，分点列出要点。")

        parts.append("\n请直接输出最终内容，不需要额外解释。")
        return "\n".join(parts)

    async def create_task(
        self,
        user_id: str,
        writing_type: str,
        topic: str,
        params: Optional[Dict[str, Any]] = None,
    ) -> Dict[str, Any]:
        """
        创建写作任务
        写入数据库 + 提交到异步队列
        """
        params = params or {}
        task_id = uuid.uuid4().hex
        now = datetime.now(timezone.utc).isoformat()

        async with get_db_conn() as conn:
            await execute(
                conn,
                """INSERT INTO writing_tasks
                   (id, user_id, writing_type, topic, params, status, created_at)
                   VALUES (?, ?, ?, ?, ?, 'pending', ?)""",
                (task_id, user_id, writing_type, topic, json.dumps(params, ensure_ascii=False), now),
            )

        # 提交到任务队列
        await self.queue.submit(
            "writing",
            {
                "task_id": task_id,
                "user_id": user_id,
                "writing_type": writing_type,
                "topic": topic,
                "params": params,
            },
            max_retries=2,
            timeout=180.0,
        )

        return {
            "task_id": task_id,
            "writing_type": writing_type,
            "topic": topic,
            "status": "pending",
            "created_at": now,
        }

    async def get_task(self, task_id: str, user_id: str) -> Optional[Dict[str, Any]]:
        """查询任务状态和结果"""
        # 先查内存队列中的实时状态
        mem_task = await self.queue.get_task(task_id)
        if mem_task and mem_task.status in (TaskStatus.PROCESSING, TaskStatus.COMPLETED, TaskStatus.FAILED):
            # 同步数据库状态
            if mem_task.status == TaskStatus.COMPLETED:
                await self._save_result(task_id, mem_task.result, None)
            elif mem_task.status == TaskStatus.FAILED:
                await self._save_result(task_id, None, mem_task.error)

        async with get_db_conn() as conn:
            task = await fetch_one(
                conn,
                "SELECT * FROM writing_tasks WHERE id = ? AND user_id = ?",
                (task_id, user_id),
            )
        return task

    async def get_history(
        self,
        user_id: str,
        page: int = 1,
        page_size: int = 20,
        writing_type: Optional[str] = None,
    ) -> Dict[str, Any]:
        """获取写作历史列表"""
        offset = (page - 1) * page_size
        conditions = ["user_id = ?"]
        params_list = [user_id]

        if writing_type:
            conditions.append("writing_type = ?")
            params_list.append(writing_type)

        where = " AND ".join(conditions)

        async with get_db_conn() as conn:
            rows = await fetch_all(
                conn,
                f"""SELECT id, writing_type, topic, status,
                           CASE WHEN result IS NOT NULL THEN SUBSTR(result, 1, 100) END as result_preview,
                           created_at
                    FROM writing_tasks WHERE {where}
                    ORDER BY created_at DESC LIMIT ? OFFSET ?""",
                tuple(params_list + [page_size, offset]),
            )
            total_row = await fetch_one(
                conn,
                f"SELECT COUNT(*) as cnt FROM writing_tasks WHERE {where}",
                tuple(params_list),
            )

        return {
            "items": rows,
            "total": total_row["cnt"] if total_row else 0,
            "page": page,
            "page_size": page_size,
        }

    async def delete_task(self, task_id: str, user_id: str) -> bool:
        """删除写作历史"""
        async with get_db_conn() as conn:
            # 先确认归属
            task = await fetch_one(
                conn,
                "SELECT id FROM writing_tasks WHERE id = ? AND user_id = ?",
                (task_id, user_id),
            )
            if not task:
                return False
            await execute(
                conn,
                "DELETE FROM writing_tasks WHERE id = ?",
                (task_id,),
            )
        return True

    async def _process_task(self, payload: Dict[str, Any]) -> str:
        """
        任务队列处理器：调用 LLM 生成写作内容
        返回生成的文本
        """
        from services.llm_service import chat_stream

        writing_type = payload["writing_type"]
        topic = payload["topic"]
        params = payload.get("params", {})
        config = WRITING_TYPES[writing_type]

        prompt = self.build_prompt(writing_type, topic, params)
        messages = [
            {"role": "system", "content": config["system_prompt"]},
            {"role": "user", "content": prompt},
        ]

        full_content = []
        error_msg = None
        async for event in chat_stream(messages, model=config["model"]):
            try:
                event_data = json.loads(event[6:])
                if event_data.get("type") == "content":
                    full_content.append(event_data["data"].get("delta", ""))
                elif event_data.get("type") == "error":
                    error_msg = event_data.get("message", event_data.get("data", {}).get("message", "上游服务错误"))
            except (json.JSONDecodeError, IndexError):
                continue

        if error_msg:
            raise ValueError(error_msg)

        result = "".join(full_content)
        if not result.strip():
            raise ValueError("LLM 返回空内容")

        return result

    async def _save_result(
        self,
        task_id: str,
        result: Optional[str],
        error: Optional[str],
    ):
        """将任务结果保存到数据库"""
        now = datetime.now(timezone.utc).isoformat()
        status = "completed" if result else "failed"

        async with get_db_conn() as conn:
            await execute(
                conn,
                """UPDATE writing_tasks
                   SET status = ?, result = ?, error = ?, completed_at = ?
                   WHERE id = ?""",
                (status, result, error, now, task_id),
            )


# 全局单例
writing_service = WritingService()
