"""
Agent 路由 - Agent 列表/详情/创建/克隆/点赞/发布/排行榜
"""
import uuid
import copy
from datetime import datetime, timezone
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query
import aiosqlite

from models import AgentCreate, AgentResponse
from auth import get_current_user, get_optional_user
from database import get_db, fetch_one, fetch_all, execute

router = APIRouter()


def _now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


async def _enrich_agent(db: aiosqlite.Connection, agent: dict, current_user_id: Optional[str] = None) -> dict:
    """补充 Agent 的作者昵称和点赞状态"""
    author = await fetch_one(
        db, "SELECT nickname FROM users WHERE id = ?", (agent["user_id"],)
    )
    if author:
        agent["nickname"] = author["nickname"]

    agent["is_liked"] = False
    if current_user_id:
        liked = await fetch_one(
            db,
            "SELECT id FROM agent_likes WHERE agent_id = ? AND user_id = ?",
            (agent["id"], current_user_id),
        )
        agent["is_liked"] = liked is not None

    return agent


# ===== Agent 列表 =====
@router.get("/api/agents")
async def list_agents(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    published_only: bool = Query(True),
    current_user: Optional[dict] = Depends(get_optional_user),
    db: aiosqlite.Connection = Depends(get_db),
):
    """获取 Agent 列表（默认只显示已发布的）"""
    offset = (page - 1) * page_size

    query = "SELECT * FROM agents"
    params = []
    conditions = []

    if published_only:
        if current_user:
            # 已登录：显示已发布的 + 自己的未发布 Agent
            conditions.append("(is_published = 1 OR user_id = ?)")
            params.append(current_user["id"])
        else:
            conditions.append("is_published = 1")

    if conditions:
        query += " WHERE " + " AND ".join(conditions)

    query += " ORDER BY likes DESC, created_at DESC LIMIT ? OFFSET ?"
    params.extend([page_size, offset])

    rows = await fetch_all(db, query, tuple(params))

    enriched = []
    for agent in rows:
        a = await _enrich_agent(db, agent, current_user["id"] if current_user else None)
        enriched.append(a)

    return {"items": enriched, "page": page, "page_size": page_size}


# ===== Agent 详情 =====
@router.get("/api/agents/{agent_id}", response_model=AgentResponse)
async def get_agent(
    agent_id: str,
    current_user: Optional[dict] = Depends(get_optional_user),
    db: aiosqlite.Connection = Depends(get_db),
):
    """获取 Agent 详情"""
    agent = await fetch_one(db, "SELECT * FROM agents WHERE id = ?", (agent_id,))
    if not agent:
        raise HTTPException(status_code=404, detail="Agent 不存在")

    agent = await _enrich_agent(db, agent, current_user["id"] if current_user else None)
    return AgentResponse(**agent)


# ===== 创建 Agent =====
@router.post("/api/agents", response_model=AgentResponse)
async def create_agent(
    body: AgentCreate,
    current_user: dict = Depends(get_current_user),
    db: aiosqlite.Connection = Depends(get_db),
):
    """创建 Agent"""
    agent_id = uuid.uuid4().hex
    created_at = _now_iso()

    await execute(
        db,
        """INSERT INTO agents (id, user_id, name, description, system_prompt,
           avatar, opening_message, likes, is_published, created_at)
           VALUES (?, ?, ?, ?, ?, ?, ?, 0, 0, ?)""",
        (agent_id, current_user["id"], body.name, body.description or "",
         body.system_prompt or "", body.avatar,
         body.opening_message or "你好！有什么可以帮你的吗？", created_at),
    )

    agent = await fetch_one(db, "SELECT * FROM agents WHERE id = ?", (agent_id,))
    agent = await _enrich_agent(db, agent, current_user["id"])
    return AgentResponse(**agent)


# ===== 克隆 Agent =====
@router.post("/api/agents/{agent_id}/clone", response_model=AgentResponse)
async def clone_agent(
    agent_id: str,
    current_user: dict = Depends(get_current_user),
    db: aiosqlite.Connection = Depends(get_db),
):
    """克隆一个 Agent 到自己名下"""
    source = await fetch_one(db, "SELECT * FROM agents WHERE id = ?", (agent_id,))
    if not source:
        raise HTTPException(status_code=404, detail="源 Agent 不存在")

    new_id = uuid.uuid4().hex
    created_at = _now_iso()

    await execute(
        db,
        """INSERT INTO agents (id, user_id, name, description, system_prompt,
           avatar, opening_message, likes, is_published, created_at)
           VALUES (?, ?, ?, ?, ?, ?, ?, 0, 0, ?)""",
        (new_id, current_user["id"], f"{source['name']} 的副本",
         source.get("description", ""), source.get("system_prompt", ""),
         source.get("avatar"), source.get("opening_message", ""), created_at),
    )

    agent = await fetch_one(db, "SELECT * FROM agents WHERE id = ?", (new_id,))
    agent = await _enrich_agent(db, agent, current_user["id"])
    return AgentResponse(**agent)


# ===== 点赞 Agent =====
@router.post("/api/agents/{agent_id}/like")
async def like_agent(
    agent_id: str,
    current_user: dict = Depends(get_current_user),
    db: aiosqlite.Connection = Depends(get_db),
):
    """点赞或取消点赞 Agent（切换）"""
    agent = await fetch_one(db, "SELECT id, likes FROM agents WHERE id = ?", (agent_id,))
    if not agent:
        raise HTTPException(status_code=404, detail="Agent 不存在")

    existing = await fetch_one(
        db,
        "SELECT id FROM agent_likes WHERE agent_id = ? AND user_id = ?",
        (agent_id, current_user["id"]),
    )

    if existing:
        await execute(db, "DELETE FROM agent_likes WHERE id = ?", (existing["id"],))
        new_likes = max(0, agent["likes"] - 1)
        await execute(db, "UPDATE agents SET likes = ? WHERE id = ?", (new_likes, agent_id))
        return {"message": "已取消点赞", "likes": new_likes, "is_liked": False}
    else:
        like_id = uuid.uuid4().hex
        await execute(
            db,
            "INSERT INTO agent_likes (id, agent_id, user_id, created_at) VALUES (?, ?, ?, ?)",
            (like_id, agent_id, current_user["id"], _now_iso()),
        )
        new_likes = agent["likes"] + 1
        await execute(db, "UPDATE agents SET likes = ? WHERE id = ?", (new_likes, agent_id))
        return {"message": "点赞成功", "likes": new_likes, "is_liked": True}


# ===== 发布 Agent =====
@router.post("/api/agents/{agent_id}/publish")
async def publish_agent(
    agent_id: str,
    current_user: dict = Depends(get_current_user),
    db: aiosqlite.Connection = Depends(get_db),
):
    """发布或取消发布 Agent（切换）"""
    agent = await fetch_one(
        db, "SELECT id, user_id, is_published FROM agents WHERE id = ?", (agent_id,)
    )
    if not agent:
        raise HTTPException(status_code=404, detail="Agent 不存在")

    if agent["user_id"] != current_user["id"]:
        raise HTTPException(status_code=403, detail="只能发布自己的 Agent")

    new_status = 0 if agent["is_published"] else 1
    await execute(
        db, "UPDATE agents SET is_published = ? WHERE id = ?", (new_status, agent_id)
    )

    return {
        "message": "已发布" if new_status else "已取消发布",
        "is_published": new_status,
    }


# ===== Agent 排行榜 =====
@router.get("/api/agents/leaderboard")
async def agent_leaderboard(
    limit: int = Query(20, ge=1, le=100),
    db: aiosqlite.Connection = Depends(get_db),
):
    """Agent 点赞排行榜"""
    rows = await fetch_all(
        db,
        """SELECT a.*, u.nickname
           FROM agents a
           LEFT JOIN users u ON a.user_id = u.id
           WHERE a.is_published = 1
           ORDER BY a.likes DESC
           LIMIT ?""",
        (limit,),
    )

    return {"items": rows, "limit": limit}
