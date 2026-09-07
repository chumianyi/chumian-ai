"""
异步任务队列 - TaskQueue
基于 asyncio.Queue 的内存任务队列，支持：
- 任务状态机（pending → processing → completed/failed）
- 重试机制（指数退避）
- 超时处理
- 并发控制（worker 数量限制）
- 后台 worker 自动消费
"""
import asyncio
import uuid
import time
from typing import Dict, Any, Callable, Awaitable, Optional
from datetime import datetime, timezone
from enum import Enum


class TaskStatus(str, Enum):
    PENDING = "pending"
    PROCESSING = "processing"
    COMPLETED = "completed"
    FAILED = "failed"
    CANCELLED = "cancelled"


class Task:
    """任务对象"""

    def __init__(
        self,
        task_id: str,
        task_type: str,
        payload: Dict[str, Any],
        max_retries: int = 3,
        timeout: float = 120.0,
    ):
        self.task_id = task_id
        self.task_type = task_type
        self.payload = payload
        self.status = TaskStatus.PENDING
        self.result: Optional[Any] = None
        self.error: Optional[str] = None
        self.retry_count = 0
        self.max_retries = max_retries
        self.timeout = timeout
        self.created_at = datetime.now(timezone.utc).isoformat()
        self.started_at: Optional[str] = None
        self.completed_at: Optional[str] = None
        self._event = asyncio.Event()

    def to_dict(self) -> Dict[str, Any]:
        return {
            "task_id": self.task_id,
            "task_type": self.task_type,
            "status": self.status.value,
            "result": self.result,
            "error": self.error,
            "retry_count": self.retry_count,
            "max_retries": self.max_retries,
            "created_at": self.created_at,
            "started_at": self.started_at,
            "completed_at": self.completed_at,
        }


class TaskQueue:
    """
    异步任务队列单例
    用法：
        queue = TaskQueue.get_instance()
        queue.register_handler("writing", writing_handler)
        task_id = await queue.submit("writing", {...})
        result = await queue.wait(task_id)
    """

    _instance: Optional["TaskQueue"] = None

    def __init__(self, max_workers: int = 4, max_queue_size: int = 1000):
        self._queue: asyncio.Queue[Task] = asyncio.Queue(maxsize=max_queue_size)
        self._tasks: Dict[str, Task] = {}
        self._handlers: Dict[str, Callable[[Dict[str, Any]], Awaitable[Any]]] = {}
        self._max_workers = max_workers
        self._workers: list[asyncio.Task] = []
        self._running = False
        self._lock = asyncio.Lock()

    @classmethod
    def get_instance(cls) -> "TaskQueue":
        """获取单例"""
        if cls._instance is None:
            cls._instance = cls()
        return cls._instance

    def register_handler(
        self,
        task_type: str,
        handler: Callable[[Dict[str, Any]], Awaitable[Any]],
    ):
        """注册任务类型处理器"""
        self._handlers[task_type] = handler

    async def start(self):
        """启动后台 worker 池"""
        if self._running:
            return
        self._running = True
        for i in range(self._max_workers):
            worker = asyncio.create_task(self._worker_loop(i), name=f"task-worker-{i}")
            self._workers.append(worker)

    async def stop(self):
        """停止所有 worker"""
        self._running = False
        for worker in self._workers:
            worker.cancel()
        self._workers.clear()

    async def submit(
        self,
        task_type: str,
        payload: Dict[str, Any],
        max_retries: int = 3,
        timeout: float = 120.0,
    ) -> str:
        """
        提交任务到队列
        返回 task_id
        """
        task_id = uuid.uuid4().hex
        task = Task(task_id, task_type, payload, max_retries, timeout)
        self._tasks[task_id] = task
        await self._queue.put(task)
        return task_id

    async def get_task(self, task_id: str) -> Optional[Task]:
        """获取任务状态"""
        return self._tasks.get(task_id)

    async def wait(self, task_id: str, timeout: float = 300.0) -> Optional[Task]:
        """等待任务完成"""
        task = self._tasks.get(task_id)
        if not task:
            return None
        try:
            await asyncio.wait_for(task._event.wait(), timeout=timeout)
        except asyncio.TimeoutError:
            pass
        return task

    async def cancel(self, task_id: str) -> bool:
        """取消待处理任务"""
        task = self._tasks.get(task_id)
        if not task or task.status != TaskStatus.PENDING:
            return False
        task.status = TaskStatus.CANCELLED
        task._event.set()
        return True

    def get_pending_count(self) -> int:
        """获取队列中待处理任务数"""
        return self._queue.qsize()

    def get_active_count(self) -> int:
        """获取正在处理的任务数"""
        return sum(
            1 for t in self._tasks.values() if t.status == TaskStatus.PROCESSING
        )

    # ===== 内部 worker =====
    async def _worker_loop(self, worker_id: int):
        """worker 主循环"""
        while self._running:
            try:
                task = await self._queue.get()
                if task.status == TaskStatus.CANCELLED:
                    self._queue.task_done()
                    continue

                await self._execute_task(task)
                self._queue.task_done()
            except asyncio.CancelledError:
                break
            except Exception as e:
                print(f"[TaskQueue] worker-{worker_id} 异常: {e}")
                await asyncio.sleep(1)

    async def _execute_task(self, task: Task):
        """执行单个任务，含重试和超时"""
        handler = self._handlers.get(task.task_type)
        if not handler:
            task.status = TaskStatus.FAILED
            task.error = f"未注册的任务类型: {task.task_type}"
            task.completed_at = datetime.now(timezone.utc).isoformat()
            task._event.set()
            return

        while task.retry_count <= task.max_retries:
            task.status = TaskStatus.PROCESSING
            task.started_at = datetime.now(timezone.utc).isoformat()

            try:
                result = await asyncio.wait_for(
                    handler(task.payload), timeout=task.timeout
                )
                task.result = result
                task.status = TaskStatus.COMPLETED
                task.completed_at = datetime.now(timezone.utc).isoformat()
                task._event.set()
                return
            except asyncio.TimeoutError:
                task.error = f"任务超时 ({task.timeout}s)"
            except Exception as e:
                task.error = str(e)

            task.retry_count += 1
            if task.retry_count <= task.max_retries:
                # 指数退避：1s, 2s, 4s...
                wait_time = min(2 ** (task.retry_count - 1), 30)
                await asyncio.sleep(wait_time)

        # 重试耗尽
        task.status = TaskStatus.FAILED
        task.completed_at = datetime.now(timezone.utc).isoformat()
        task._event.set()
