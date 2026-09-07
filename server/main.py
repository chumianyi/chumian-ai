"""
触面 AI - FastAPI 服务端入口
启动方式：
  python3 main.py
  uvicorn main:app --host 0.0.0.0 --port 24512
"""
import os
import uvicorn
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from config import settings
from database import init_db, close_db

# 导入所有路由
from routes.auth import router as auth_router
from routes.chat import router as chat_router
from routes.user import router as user_router
from routes.posts import router as posts_router
from routes.agents import router as agents_router
from routes.shop import router as shop_router
from routes.activity import router as activity_router
from routes.search import router as search_router
from routes.notifications import router as notifications_router
from routes.legal import router as legal_router

# 扩充模块路由
from routes.writing import router as writing_router
from routes.image_gen import router as image_gen_router
from routes.analytics import router as analytics_router
from routes.admin import router as admin_router
from routes.feedback import router as feedback_router
from routes.push import router as push_router
from routes.friends import router as friends_router
from routes.achievements import router as achievements_router
from routes.wallet import router as wallet_router

# 新增模块路由
from routes.voice import router as voice_router
from routes.music import router as music_router
from routes.export import router as export_router
from routes.plugins import router as plugins_router
from routes.ws import router as ws_router


@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    应用生命周期管理
    启动时初始化数据库，关闭时释放资源
    """
    # 启动：初始化数据库
    print(f"[启动] 正在初始化数据库: {settings.DB_PATH}")
    await init_db()
    print("[启动] 数据库初始化完成")

    # 执行扩充模块数据库迁移
    from migrations import run_migrations
    version = await run_migrations()
    print(f"[启动] 数据库迁移完成，版本: v{version}")

    # 启动异步任务队列
    from services.task_queue import TaskQueue
    queue = TaskQueue.get_instance()
    await queue.start()
    print("[启动] 异步任务队列已启动 (4 workers)")

    # 确保 media 目录存在
    os.makedirs(settings.MEDIA_DIR, exist_ok=True)
    print(f"[启动] 媒体目录: {settings.MEDIA_DIR}")

    # 打印配置信息
    print(f"[启动] 服务端口: {settings.PORT}")
    print(f"[启动] LLM 上游: {'智谱 API (已配置)' if settings.ZHIPU_API_KEY else '未配置 (调用将返回 503)'}")
    print(f"[启动] 搜索服务: {'真实搜索 (已配置)' if settings.SEARCH_API_KEY else '未配置 (返回空结果)'}")

    yield

    # 关闭：释放数据库连接
    print("[关闭] 正在停止任务队列...")
    await queue.stop()
    print("[关闭] 正在释放资源...")
    await close_db()
    print("[关闭] 服务已停止")


# 创建 FastAPI 应用
app = FastAPI(
    title="触面 AI 服务端",
    description="触面 AI 完整后端 API - 支持 AI 对话、社区、Agent、积分商城等",
    version="1.0.0",
    lifespan=lifespan,
)

# ===== CORS 中间件（允许所有来源，开发用）=====
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ===== 静态文件服务：/media 指向 CHUMIAN_MEDIA_DIR =====
os.makedirs(settings.MEDIA_DIR, exist_ok=True)
app.mount("/media", StaticFiles(directory=settings.MEDIA_DIR), name="media")

# ===== 注册所有路由 =====
app.include_router(auth_router)
app.include_router(chat_router)
app.include_router(user_router)
app.include_router(posts_router)
app.include_router(agents_router)
app.include_router(shop_router)
app.include_router(activity_router)
app.include_router(search_router)
app.include_router(notifications_router)
app.include_router(legal_router)

# ===== 注册扩充模块路由 =====
app.include_router(writing_router)
app.include_router(image_gen_router)
app.include_router(analytics_router)
app.include_router(admin_router)
app.include_router(feedback_router)
app.include_router(push_router)
app.include_router(friends_router)
app.include_router(achievements_router)
app.include_router(wallet_router)

# ===== 注册新增模块路由 =====
app.include_router(voice_router)
app.include_router(music_router)
app.include_router(export_router)
app.include_router(plugins_router)
app.include_router(ws_router)


# ===== 健康检查端点 =====
@app.get("/health")
async def health_check():
    """
    健康检查端点
    返回服务状态、版本、时间
    """
    from datetime import datetime, timezone
    return {
        "status": "ok",
        "version": "1.0.0",
        "service": "触面 AI 服务端",
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "llm_configured": bool(settings.ZHIPU_API_KEY),
        "search_configured": bool(settings.SEARCH_API_KEY),
    }


@app.get("/")
async def root():
    """根路径：返回 API 信息"""
    return {
        "name": "触面 AI 服务端",
        "version": "1.0.0",
        "docs": "/docs",
        "health": "/health",
        "endpoints": {
            "auth": "/api/auth/*",
            "chat": "/api/chat/*",
            "conversations": "/api/conversations/*",
            "user": "/api/user/*",
            "posts": "/api/posts/*",
            "agents": "/api/agents/*",
            "shop": "/api/shop/*",
            "search": "/api/search",
            "notifications": "/api/notifications/*",
            "legal": "/api/legal/*",
            "writing": "/api/writing/*",
            "image_gen": "/api/image/*",
            "analytics": "/api/analytics/*",
            "admin": "/api/admin/*",
            "feedback": "/api/feedback/*",
            "push": "/api/push/*",
            "friends": "/api/friends/*",
            "achievements": "/api/achievements/*",
            "wallet": "/api/wallet/*",
            "voice": "/api/voice/*",
            "music": "/api/music/*",
            "export": "/api/export/*",
            "plugins": "/api/plugins/*",
            "websocket": "/api/ws/*",
        },
    }


# ===== 直接运行入口 =====
if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=settings.PORT,
        reload=False,
        log_level="info",
    )
