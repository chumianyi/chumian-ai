"""
联网搜索路由 - 搜索、搜索建议
未配置 SEARCH_API_KEY 时返回空结果列表，绝不编造搜索条目
"""
from typing import List

from fastapi import APIRouter, Query

from models import SearchResponse, SearchResult
from services.search_service import search, get_suggestions
from config import settings

router = APIRouter()


# ===== 搜索 =====
@router.get("/api/search")
async def search_endpoint(
    q: str = Query(..., description="搜索关键词"),
):
    """
    联网搜索
    未配置 SEARCH_API_KEY 时返回空结果列表（HTTP 200，空结果不是错误）
    """
    if not q or not q.strip():
        return {"query": q, "results": [], "message": "搜索关键词不能为空"}

    # 未配置搜索 Key 时返回空结果
    if not settings.SEARCH_API_KEY:
        return {
            "query": q,
            "results": [],
            "message": "搜索服务未配置",
        }

    results: List[SearchResult] = await search(q)
    return {
        "query": q,
        "results": [r.dict() for r in results],
    }


# ===== 搜索建议 =====
@router.get("/api/search/suggest")
async def search_suggest(
    q: str = Query("", description="输入的关键词"),
):
    """
    搜索建议
    根据用户输入返回相关搜索建议
    """
    suggestions = get_suggestions(q)
    return {
        "query": q,
        "suggestions": suggestions,
    }
