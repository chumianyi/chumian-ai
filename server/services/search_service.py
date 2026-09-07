"""
搜索服务 - 联网搜索 + 启发式判断 + 结果格式化
未配置 SEARCH_API_KEY 时返回空列表，绝不编造搜索结果
"""
import re
import httpx
from typing import List, Dict, Optional

from config import settings
from models import SearchResult


# ===== 需要搜索的关键词启发式 =====
SEARCH_KEYWORDS = [
    "今天", "最新", "新闻", "天气", "股价", "行情", "比赛", "比分",
    "怎么回事", "是什么", "谁是", "哪里", "什么时候", "多少",
    "价格", "汇率", "票房", "销量", "人口", "面积", "海拔",
    "官网", "下载", "地址", "电话", "营业时间", "门票",
    "翻译", "英文", "日文", "韩文", "法文", "德文",
    " recipe", "how to", "what is", "who is", "where is",
    "2024", "2025", "2026", "今年", "去年", "明年",
    "地震", "台风", "疫情", "政策", "法规", "选举",
    "世界杯", "奥运会", "NBA", "欧冠", "英超", "西甲",
]


def should_search(query: str) -> bool:
    """
    判断是否需要联网搜索
    基于关键词启发式：包含时效性/事实性关键词时返回 True
    """
    if not query or len(query) < 2:
        return False

    query_lower = query.lower()

    # 匹配关键词
    for keyword in SEARCH_KEYWORDS:
        if keyword.lower() in query_lower:
            return True

    # 包含问号且长度适中，可能是事实性问题
    if ("?" in query or "？" in query) and len(query) < 100:
        return True

    return False


# ===== 真实搜索 API 调用 =====
async def _real_search(query: str) -> List[Dict]:
    """调用真实搜索 API（需要配置 SEARCH_API_KEY）"""
    try:
        async with httpx.AsyncClient(timeout=15.0) as client:
            url = f"{settings.SEARCH_BASE_URL}/tools/search"
            headers = {
                "Authorization": f"Bearer {settings.SEARCH_API_KEY}",
                "Content-Type": "application/json",
            }
            payload = {"query": query}

            response = await client.post(url, headers=headers, json=payload)
            if response.status_code == 200:
                data = response.json()
                results = data.get("results", data.get("data", []))
                if isinstance(results, list):
                    return [
                        {
                            "title": r.get("title", ""),
                            "snippet": r.get("snippet", r.get("content", "")),
                            "url": r.get("url", r.get("link", "")),
                            "source": r.get("source", r.get("site", "")),
                        }
                        for r in results
                        if r.get("title") or r.get("url")
                    ]
    except Exception:
        pass

    # 搜索失败返回空列表，不编造结果
    return []


# ===== 对外接口 =====
async def search(query: str) -> List[SearchResult]:
    """
    执行搜索，返回 SearchResult 列表
    未配置 SEARCH_API_KEY 时返回空列表
    """
    if not query or not query.strip():
        return []

    if not settings.SEARCH_API_KEY:
        return []

    raw_results = await _real_search(query)
    return [SearchResult(**r) for r in raw_results]


def format_results_for_prompt(results: List[SearchResult]) -> str:
    """
    将搜索结果格式化为可注入 prompt 的文本
    """
    if not results:
        return ""

    lines = ["【联网搜索参考信息】"]
    for i, r in enumerate(results[:5], 1):
        lines.append(f"\n[{i}] {r.title}")
        lines.append(f"摘要: {r.snippet}")
        lines.append(f"来源: {r.source or r.url}")
        lines.append(f"链接: {r.url}")

    lines.append("\n请结合以上信息回答用户问题，必要时引用来源编号。")
    return "\n".join(lines)


# ===== 搜索建议 =====
SUGGESTIONS_DB = [
    "人工智能最新进展", "Python教程", "今天天气", "世界杯赛程",
    "股市行情", "机器学习入门", "前端框架对比", "数据库设计",
    "API设计最佳实践", "微服务架构", "Docker入门", "Kubernetes教程",
    "大语言模型原理", "RAG检索增强", "Agent智能体", "Prompt工程",
]


def get_suggestions(query: str) -> List[str]:
    """获取搜索建议"""
    if not query:
        return SUGGESTIONS_DB[:8]

    query_lower = query.lower()
    matched = [s for s in SUGGESTIONS_DB if query_lower in s.lower()]

    # 如果匹配不够，补充一些通用建议
    if len(matched) < 5:
        for s in SUGGESTIONS_DB:
            if s not in matched:
                matched.append(s)
            if len(matched) >= 8:
                break

    return matched[:8]
