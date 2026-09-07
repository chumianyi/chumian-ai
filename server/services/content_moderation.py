"""
内容审核服务 - ContentModeration
功能：
- 敏感词过滤（内置词库 + 可扩展）
- AI 内容检测（调用 LLM 审核，无 Key 时回退到关键词自动审核）
- 自动审核（评分 + 分级）
- 人工审核队列管理
"""
import re
import uuid
import asyncio
from typing import List, Dict, Any, Optional, Tuple
from datetime import datetime, timezone

from database import get_db_conn, fetch_one, fetch_all, execute


# ===== 内置敏感词库（分级） =====
SENSITIVE_WORDS = {
    "high": [
        "赌博", "博彩", "色情", "淫秽", "毒品", "吸毒",
        "枪支", "炸药", "恐怖", "分裂", "颠覆",
    ],
    "medium": [
        "广告", "推广", "加微信", "加QQ", "联系方式",
        "代购", "刷单", "兼职", "赚钱",
    ],
    "low": [
        "垃圾", "废物", "滚蛋", "闭嘴",
    ],
}

# 敏感词替换符
MASK_CHAR = "*"


class ModerationResult:
    """审核结果"""

    def __init__(
        self,
        passed: bool,
        score: float,
        level: str,
        matched_words: List[str],
        reason: str = "",
    ):
        self.passed = passed
        self.score = score  # 0.0(安全) - 1.0(危险)
        self.level = level  # safe / warning / danger
        self.matched_words = matched_words
        self.reason = reason

    def to_dict(self) -> Dict[str, Any]:
        return {
            "passed": self.passed,
            "score": self.score,
            "level": self.level,
            "matched_words": self.matched_words,
            "reason": self.reason,
        }


class ContentModeration:
    """内容审核服务"""

    def __init__(self):
        # 编译敏感词正则
        self._patterns = {}
        for level, words in SENSITIVE_WORDS.items():
            if words:
                pattern = "|".join(re.escape(w) for w in words)
                self._patterns[level] = re.compile(pattern, re.IGNORECASE)

    def filter_text(self, text: str) -> Tuple[str, List[str]]:
        """
        敏感词过滤：将敏感词替换为 *
        返回 (过滤后文本, 匹配到的词列表)
        """
        matched = []
        filtered = text
        for level, pattern in self._patterns.items():
            def _replace(m):
                word = m.group(0)
                matched.append(word)
                return MASK_CHAR * len(word)
            filtered = pattern.sub(_replace, filtered)
        return filtered, matched

    def auto_check(self, text: str) -> ModerationResult:
        """
        自动审核：基于敏感词匹配评分
        评分规则：
        - high 级词：每个 +0.4
        - medium 级词：每个 +0.2
        - low 级词：每个 +0.1
        - 超过 0.6 判定为 danger，0.3-0.6 为 warning
        """
        score = 0.0
        all_matched = []

        for level, pattern in self._patterns.items():
            matches = pattern.findall(text)
            if matches:
                all_matched.extend(matches)
                weight = {"high": 0.4, "medium": 0.2, "low": 0.1}.get(level, 0.1)
                score += len(matches) * weight

        score = min(score, 1.0)

        if score >= 0.6:
            return ModerationResult(
                passed=False, score=score, level="danger",
                matched_words=all_matched,
                reason="包含高危敏感词，已自动拦截",
            )
        elif score >= 0.3:
            return ModerationResult(
                passed=True, score=score, level="warning",
                matched_words=all_matched,
                reason="包含敏感词，已过滤并标记人工复审",
            )
        else:
            return ModerationResult(
                passed=True, score=score, level="safe",
                matched_words=[], reason="",
            )

    async def ai_check(self, text: str) -> ModerationResult:
        """
        AI 内容检测：调用 LLM 进行语义级审核
        无 API Key 时回退到关键词自动审核结果
        """
        from config import settings
        from services.llm_service import chat_stream

        # 先做快速自动审核
        auto_result = self.auto_check(text)

        if not settings.ZHIPU_API_KEY:
            return auto_result

        # 调用 LLM 审核
        prompt = (
            "你是一个内容审核专家。请判断以下内容是否包含违规信息"
            "（暴力、色情、政治敏感、诈骗、广告引流等）。\n"
            "只回复 JSON：{\"safe\": true/false, \"score\": 0-1, \"reason\": \"原因\"}\n\n"
            f"内容：{text[:500]}"
        )

        try:
            full_response = []
            async for event in chat_stream(
                [{"role": "user", "content": prompt}],
                model="glm-4-flash",
            ):
                import json
                try:
                    payload = json.loads(event[6:])
                    if payload.get("type") == "content":
                        full_response.append(payload["data"].get("delta", ""))
                except (json.JSONDecodeError, IndexError):
                    continue

            result_text = "".join(full_response)
            import json as _json
            ai_result = _json.loads(result_text)
            safe = ai_result.get("safe", True)
            score = ai_result.get("score", 0.0)
            reason = ai_result.get("reason", "")

            level = "danger" if score >= 0.6 else ("warning" if score >= 0.3 else "safe")
            return ModerationResult(
                passed=safe, score=score, level=level,
                matched_words=auto_result.matched_words, reason=reason,
            )
        except Exception:
            return auto_result

    async def submit_for_review(
        self,
        content_type: str,
        content_id: str,
        user_id: Optional[str],
        content: str,
        auto_result: Optional[ModerationResult] = None,
    ) -> str:
        """
        提交内容到人工审核队列
        返回审核记录 ID
        """
        if auto_result is None:
            auto_result = self.auto_check(content)

        review_id = uuid.uuid4().hex
        now = datetime.now(timezone.utc).isoformat()

        async with get_db_conn() as conn:
            await execute(
                conn,
                """INSERT INTO content_reviews
                   (id, content_type, content_id, user_id, content,
                    auto_result, auto_score, status, created_at)
                   VALUES (?, ?, ?, ?, ?, ?, ?, 'pending', ?)""",
                (
                    review_id, content_type, content_id, user_id,
                    content[:2000], auto_result.level, auto_result.score, now,
                ),
            )

        return review_id

    async def get_review_queue(
        self,
        status: str = "pending",
        page: int = 1,
        page_size: int = 20,
    ) -> Dict[str, Any]:
        """获取人工审核队列"""
        offset = (page - 1) * page_size

        async with get_db_conn() as conn:
            rows = await fetch_all(
                conn,
                """SELECT * FROM content_reviews WHERE status = ?
                   ORDER BY created_at DESC LIMIT ? OFFSET ?""",
                (status, page_size, offset),
            )
            total_row = await fetch_one(
                conn,
                "SELECT COUNT(*) as cnt FROM content_reviews WHERE status = ?",
                (status,),
            )

        return {
            "items": rows,
            "total": total_row["cnt"] if total_row else 0,
            "page": page,
            "page_size": page_size,
        }

    async def review_content(
        self,
        review_id: str,
        reviewer_id: str,
        approved: bool,
        note: str = "",
    ) -> bool:
        """人工审核：通过/拒绝"""
        now = datetime.now(timezone.utc).isoformat()
        status = "approved" if approved else "rejected"

        async with get_db_conn() as conn:
            result = await execute(
                conn,
                """UPDATE content_reviews
                   SET status = ?, reviewer_id = ?, review_note = ?, reviewed_at = ?
                   WHERE id = ?""",
                (status, reviewer_id, note, now, review_id),
            )
            return result is not None


# 全局单例
content_moderation = ContentModeration()
