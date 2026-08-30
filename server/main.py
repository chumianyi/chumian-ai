import asyncio
import json
import time
import uuid
import hashlib
import random
import re
import smtplib
from email.mime.text import MIMEText
from datetime import datetime, timedelta
from pathlib import Path
import os
import aiosqlite
import httpx
from fastapi import FastAPI, HTTPException, Request, Response, Form, UploadFile, File
from fastapi.responses import StreamingResponse, JSONResponse, FileResponse
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional, List, Dict, Any

GLM_API_KEY = "d0a99ebaa97e4bac9e99e236211b15f5.m8eJh0XSXMVu2I8P"

# GitHub OAuth Config (可配置)
GITHUB_CLIENT_ID = os.environ.get("GITHUB_CLIENT_ID", "Iv23liXKq2Q8Zb1nL2cD")
GITHUB_CLIENT_SECRET = os.environ.get("GITHUB_CLIENT_SECRET", "")
GITHUB_REDIRECT_URI = "chumianai://auth/callback"
GLM_BASE_URL = "https://open.bigmodel.cn/api/paas/v4"
SMTP_HOST = "smtp.qq.com"
SMTP_PORT = 465
SMTP_USER = "3930535663@qq.com"
SMTP_PASS = "q98Sk31J"
AUTH_CODE = "q98Sk31J"

DB_PATH = os.environ.get("CHUMIAN_DB_PATH", str(Path(__file__).parent / "data" / "chumian.db"))
MEDIA_DIR = Path(os.environ.get("CHUMIAN_MEDIA_DIR", str(Path(__file__).parent / "media")))
MEDIA_DIR.mkdir(parents=True, exist_ok=True)

TEXT_MODELS = ["glm-4-flash", "glm-4-flash-250414", "glm-4.7-flash", "glm-z1-flash"]
VISION_MODELS = ["glm-4v-flash", "glm-4.6v-flash", "glm-4.1v-thinking-flash"]
IMAGE_MODEL = "cogview-3-flash"
VIDEO_MODEL = "cogvideox-flash"
ALL_MODELS = TEXT_MODELS + VISION_MODELS + [IMAGE_MODEL, VIDEO_MODEL]

BANNED_WORDS = ["色情", "暴力", "恐怖", "赌博", "毒品", "自杀", "杀人", "炸弹", "枪支", "反动"]

verification_codes = {}
video_tasks = {}

SYSTEM_PROMPT = """你是「初眠」，一个温柔、聪明、善解人意的AI助手。
你会用Markdown格式回复用户，支持标题、加粗、斜体、列表、代码块等格式。
请始终保持友好、有帮助的态度。"""

async def extract_search_keyword(user_message: str) -> str:
    """调用GLM从用户消息中提取搜索关键词。寒暄类返回NO_SEARCH。"""
    try:
        async with httpx.AsyncClient(timeout=8.0) as client:
            payload = {
                "model": "glm-4-flash",
                "messages": [
                    {"role": "system", "content": "你是一个搜索关键词提取助手。请从用户问题中提取最适合用于网络搜索的关键词。规则：1.只返回关键词本身，不要任何解释、引号、标点；2.如果是寒暄问候闲聊（如你好、谢谢、在吗、嗨），不需要搜索，返回NO_SEARCH；3.纯计算、纯闲聊、不需要联网的问题返回NO_SEARCH；4.关键词简洁准确，不超过20个字；5.提取核心实体和问题，去掉语气词。"},
                    {"role": "user", "content": "用户问题：%s\n\n关键词：" % user_message}
                ],
                "stream": False
            }
            headers = {"Authorization": "Bearer %s" % GLM_API_KEY, "Content-Type": "application/json"}
            resp = await client.post("%s/chat/completions" % GLM_BASE_URL, json=payload, headers=headers)
            data = resp.json()
            keyword = data["choices"][0]["message"]["content"].strip().strip('"').strip("'").strip()
            # 清理可能的前缀
            for prefix in ["关键词：", "关键词:", "搜索关键词：", "搜索关键词:"]:
                if keyword.startswith(prefix):
                    keyword = keyword[len(prefix):].strip()
            if not keyword or len(keyword) > 30:
                return user_message[:20]
            return keyword
    except Exception as e:
        print("关键词提取失败，fallback:", e)
        return user_message[:20]

async def web_search(query: str, max_results: int = 5) -> List[Dict[str, str]]:
    """使用必应(cn.bing.com)搜索，不存储结果，实时获取实时返回。"""
    results = []
    try:
        async with httpx.AsyncClient(timeout=12.0, follow_redirects=True) as client:
            resp = await client.get(
                "https://cn.bing.com/search",
                params={"q": query, "setlang": "zh-CN"},
                headers={
                    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
                    "Accept-Language": "zh-CN,zh;q=0.9,en;q=0.8",
                }
            )
            if resp.status_code != 200:
                return results
            html = resp.text
            blocks = re.findall(r'<li[^>]*class="b_algo"[^>]*>(.*?)</li>', html, re.DOTALL)
            for block in blocks:
                title_m = re.search(r'<h2[^>]*>\s*<a[^>]*href="([^"]*)"[^>]*>(.*?)</a>', block, re.DOTALL)
                if not title_m:
                    continue
                if len(results) >= max_results:
                    break
                url = title_m.group(1).replace("&amp;", "&")
                title = re.sub(r"<[^>]+>", "", title_m.group(2)).strip()
                snippet_m = re.search(r'<p[^>]*>(.*?)</p>', block, re.DOTALL)
                snippet = re.sub(r"<[^>]+>", "", snippet_m.group(1)).strip() if snippet_m else ""
                source_m = re.search(r"https?://([^/]+)", url)
                results.append({
                    "title": title,
                    "snippet": snippet,
                    "url": url,
                    "source": source_m.group(1) if source_m else ""
                })
    except Exception:
        pass
    return results

app = FastAPI()
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.on_event("startup")
async def startup_event():
    await init_db()
    asyncio.ensure_future(cleanup_media())

async def get_db():
    db = await aiosqlite.connect(DB_PATH)
    db.row_factory = aiosqlite.Row
    return db

async def init_db():
    db = await get_db()
    await db.executescript("""
        CREATE TABLE IF NOT EXISTS users (
            id TEXT PRIMARY KEY,
            email TEXT UNIQUE NOT NULL,
            password_hash TEXT NOT NULL,
            nickname TEXT NOT NULL,
            token TEXT UNIQUE,
            daily_points INTEGER DEFAULT 90000000,
            last_reset TEXT,
            is_banned INTEGER DEFAULT 0,
            ban_until TEXT,
            ban_reason TEXT,
            oobe_completed INTEGER DEFAULT 0,
            avatar TEXT,
            github_id TEXT,
            created_at TEXT
        );
        CREATE TABLE IF NOT EXISTS conversations (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            title TEXT,
            model TEXT,
            created_at TEXT,
            FOREIGN KEY (user_id) REFERENCES users(id)
        );
        CREATE TABLE IF NOT EXISTS messages (
            id TEXT PRIMARY KEY,
            conversation_id TEXT NOT NULL,
            role TEXT NOT NULL,
            content TEXT NOT NULL,
            think_content TEXT,
            model TEXT,
            tokens_used INTEGER DEFAULT 0,
            image_url TEXT,
            video_url TEXT,
            created_at TEXT,
            FOREIGN KEY (conversation_id) REFERENCES conversations(id)
        );
        CREATE TABLE IF NOT EXISTS posts (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            title TEXT NOT NULL,
            content TEXT NOT NULL,
            likes INTEGER DEFAULT 0,
            comments_count INTEGER DEFAULT 0,
            approved INTEGER DEFAULT 0,
            created_at TEXT,
            FOREIGN KEY (user_id) REFERENCES users(id)
        );
        CREATE TABLE IF NOT EXISTS comments (
            id TEXT PRIMARY KEY,
            post_id TEXT NOT NULL,
            user_id TEXT NOT NULL,
            content TEXT NOT NULL,
            created_at TEXT,
            FOREIGN KEY (post_id) REFERENCES posts(id),
            FOREIGN KEY (user_id) REFERENCES users(id)
        );
        CREATE TABLE IF NOT EXISTS post_likes (
            id TEXT PRIMARY KEY,
            post_id TEXT NOT NULL,
            user_id TEXT NOT NULL,
            created_at TEXT,
            UNIQUE(post_id, user_id)
        );
        CREATE TABLE IF NOT EXISTS agents (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            name TEXT NOT NULL,
            description TEXT,
            system_prompt TEXT,
            opening_message TEXT,
            avatar TEXT,
            created_at TEXT,
            FOREIGN KEY (user_id) REFERENCES users(id)
        );
        CREATE TABLE IF NOT EXISTS points_log (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            points INTEGER,
            reason TEXT,
            created_at TEXT,
            FOREIGN KEY (user_id) REFERENCES users(id)
        );
    """)
    await db.commit()
    # Migration: add new columns if not exist
    migrations = [
        "ALTER TABLE agents ADD COLUMN likes INTEGER DEFAULT 0",
        "ALTER TABLE agents ADD COLUMN download_count INTEGER DEFAULT 0",
        "ALTER TABLE agents ADD COLUMN is_published INTEGER DEFAULT 0",
        "ALTER TABLE posts ADD COLUMN type TEXT DEFAULT 'text'",
        "ALTER TABLE posts ADD COLUMN media_url TEXT",
        "ALTER TABLE posts ADD COLUMN agent_id TEXT",
        "ALTER TABLE users ADD COLUMN github_id TEXT",
    ]
    for m in migrations:
        try:
            await db.execute(m)
        except Exception:
            pass
    try:
        await db.execute("""
            CREATE TABLE IF NOT EXISTS agent_likes (
                id TEXT PRIMARY KEY,
                agent_id TEXT NOT NULL,
                user_id TEXT NOT NULL,
                created_at TEXT,
                UNIQUE(agent_id, user_id)
            )
        """)
    except Exception:
        pass
    # New tables for v2.0
    new_tables = """
        CREATE TABLE IF NOT EXISTS checkins (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            checkin_date TEXT NOT NULL,
            premium_points INTEGER DEFAULT 0,
            streak INTEGER DEFAULT 0,
            created_at TEXT,
            UNIQUE(user_id, checkin_date)
        );
        CREATE TABLE IF NOT EXISTS followings (
            id TEXT PRIMARY KEY,
            follower_id TEXT NOT NULL,
            following_id TEXT NOT NULL,
            created_at TEXT,
            UNIQUE(follower_id, following_id)
        );
        CREATE TABLE IF NOT EXISTS notifications (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            type TEXT NOT NULL,
            title TEXT NOT NULL,
            content TEXT,
            related_id TEXT,
            is_read INTEGER DEFAULT 0,
            created_at TEXT
        );
        CREATE TABLE IF NOT EXISTS activity_guess (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            guess_date TEXT NOT NULL,
            bet_points INTEGER NOT NULL,
            choice TEXT NOT NULL,
            result TEXT,
            won INTEGER DEFAULT 0,
            points_change INTEGER DEFAULT 0,
            created_at TEXT,
            UNIQUE(user_id, guess_date)
        );
        CREATE TABLE IF NOT EXISTS agent_applications (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            reason TEXT NOT NULL,
            status TEXT DEFAULT 'pending',
            review_result TEXT,
            created_at TEXT,
            reviewed_at TEXT,
            UNIQUE(user_id)
        );
    """
    await db.executescript(new_tables)
    # New user fields
    user_migrations = [
        "ALTER TABLE users ADD COLUMN premium_points INTEGER DEFAULT 0",
        "ALTER TABLE users ADD COLUMN svip_type TEXT DEFAULT 'none'",
        "ALTER TABLE users ADD COLUMN svip_expire TEXT",
        "ALTER TABLE users ADD COLUMN qq TEXT",
        "ALTER TABLE users ADD COLUMN birthday TEXT",
        "ALTER TABLE users ADD COLUMN likes_count INTEGER DEFAULT 0",
    ]
    for m in user_migrations:
        try:
            await db.execute(m)
        except Exception:
            pass
    await db.commit()
    await db.close()

def hash_password(password):
    return hashlib.sha256(password.encode()).hexdigest()

def send_verification_email(email, code):
    msg = MIMEText("""亲爱的初眠AI用户：

您的初眠AI注册验证码为：%s
该验证码将在5分钟内有效。

如果这不是您的操作，请忽略此邮件。

—— 初眠AI 团队
""" % code, 'plain', 'utf-8')
    msg['Subject'] = '初眠AI - 邮箱验证码'
    msg['From'] = SMTP_USER
    msg['To'] = email
    try:
        server = smtplib.SMTP_SSL(SMTP_HOST, SMTP_PORT)
        server.login(SMTP_USER, SMTP_PASS)
        server.sendmail(SMTP_USER, [email], msg.as_string())
        server.quit()
        return True
    except Exception as e:
        print("Email error: %s" % str(e))
        return False

def check_banned_content(text):
    text_lower = text.lower()
    for word in BANNED_WORDS:
        if word in text_lower:
            return True
    return False

async def glm_moderate(text):
    try:
        async with httpx.AsyncClient(timeout=15.0) as client:
            payload = {
                "model": "glm-4-flash",
                "messages": [
                    {"role": "system", "content": "你是内容审核员。判断以下内容是否包含违规内容（色情、暴力、恐怖、赌博、毒品、自杀、杀人、反动、诈骗等）。只回复JSON：{\"violation\": true/false, \"reason\": \"原因\"}"},
                    {"role": "user", "content": text[:2000]}
                ],
                "stream": False
            }
            headers = {"Authorization": "Bearer %s" % GLM_API_KEY, "Content-Type": "application/json"}
            resp = await client.post("%s/chat/completions" % GLM_BASE_URL, json=payload, headers=headers)
            data = resp.json()
            result = data["choices"][0]["message"]["content"]
            try:
                parsed = json.loads(result)
                return parsed.get("violation", False), parsed.get("reason", "")
            except:
                return check_banned_content(text), ""
    except:
        return check_banned_content(text), ""

async def get_user_by_token(token):
    if not token:
        return None
    db = await get_db()
    cursor = await db.execute("SELECT * FROM users WHERE token = ?", (token,))
    user = await cursor.fetchone()
    await db.close()
    if user:
        return dict(user)
    return None

async def reset_daily_points(user_id):
    db = await get_db()
    today = datetime.now().strftime("%Y-%m-%d")
    await db.execute("UPDATE users SET daily_points = 90000000, last_reset = ? WHERE id = ? AND (last_reset IS NULL OR last_reset < ?)", (today, user_id, today))
    await db.commit()
    await db.close()

async def cleanup_media():
    while True:
        try:
            now = time.time()
            for f in MEDIA_DIR.glob("*"):
                if f.is_file() and now - f.stat().st_mtime > 86400:
                    f.unlink()
                    print("Cleaned up %s" % f)
        except Exception as e:
            print("Cleanup error: %s" % str(e))
        await asyncio.sleep(3600)

class RegisterRequest(BaseModel):
    username: str
    password: str
    nickname: str

class LoginRequest(BaseModel):
    username: str
    password: str

class SendCodeRequest(BaseModel):
    email: str

class VerifyAppRequest(BaseModel):
    package_name: str
    apk_md5: str

class ChatRequest(BaseModel):
    conversation_id: Optional[str] = None
    message: str
    model: Optional[str] = "glm-4-flash"
    image_url: Optional[str] = None
    agent_id: Optional[str] = None
    web_search: Optional[bool] = False

class GenerateImageRequest(BaseModel):
    prompt: str
    size: Optional[str] = "1024x1024"

class PostCreateRequest(BaseModel):
    title: str
    content: str
    type: str = "image"
    media_url: str = ""
    agent_id: str = ""

class CommentCreateRequest(BaseModel):
    content: str

class AgentCreateRequest(BaseModel):
    name: str
    description: str
    system_prompt: str
    opening_message: Optional[str] = ""
    avatar: Optional[str] = ""

@app.middleware("http")
async def auth_middleware(request: Request, call_next):
    public_paths = ["/api/auth/send-code", "/api/auth/register", "/api/auth/login", "/api/auth/github", "/api/auth/github/bind", "/api/verify-app", "/media/", "/api/models", "/api/templates", "/api/health"]
    public_get_paths = ["/api/agents", "/api/posts", "/api/explore"]
    path = request.url.path
    method = request.method
    for p in public_paths:
        if path.startswith(p):
            return await call_next(request)
    if method == "GET":
        for p in public_get_paths:
            if path.startswith(p):
                return await call_next(request)
    token = request.cookies.get("token") or ""
    auth_header = request.headers.get("Authorization", "")
    if auth_header.startswith("Bearer "):
        token = auth_header[7:]
    user = await get_user_by_token(token)
    if not user:
        return JSONResponse(status_code=401, content={"error": "未登录"})
    if user["is_banned"]:
        ban_until = user["ban_until"]
        if ban_until and datetime.fromisoformat(ban_until) > datetime.now():
            return JSONResponse(status_code=403, content={"error": "账号已被封禁至 %s" % ban_until, "ban_until": ban_until})
    # GitHub binding check: unbound users can only access binding-related endpoints
    if not user.get("github_id"):
        unbound_allowed = ["/api/auth/github", "/api/auth/logout", "/api/user/info"]
        allowed = False
        for p in unbound_allowed:
            if path.startswith(p):
                allowed = True
                break
        if not allowed:
            return JSONResponse(status_code=403, content={"error": "您的账号未绑定 GitHub，拒绝访问", "need_github_bind": True})
    await reset_daily_points(user["id"])
    request.state.user = user
    return await call_next(request)

@app.post("/api/auth/send-code")
async def send_code(req: SendCodeRequest):
    if not req.email.endswith("@qq.com"):
        raise HTTPException(400, "仅支持QQ邮箱注册")
    code = ''.join(random.choices('0123456789', k=6))
    verification_codes[req.email] = {"code": code, "expires": time.time() + 300}
    sent = send_verification_email(req.email, code)
    return {"success": True, "message": "验证码已发送", "dev_code": code if not sent else None}

@app.post("/api/auth/register")
async def register(req: RegisterRequest):
    if len(req.username) < 2:
        raise HTTPException(400, "用户名至少2位")
    if len(req.password) < 4:
        raise HTTPException(400, "密码至少4位")
    if not req.nickname:
        raise HTTPException(400, "请输入昵称")
    db = await get_db()
    cursor = await db.execute("SELECT id FROM users WHERE email = ?", (req.username,))
    if await cursor.fetchone():
        await db.close()
        raise HTTPException(400, "该账号已注册")
    user_id = str(uuid.uuid4())
    token = str(uuid.uuid4())
    now = datetime.now().isoformat()
    await db.execute(
        "INSERT INTO users (id, email, password_hash, nickname, token, last_reset, created_at) VALUES (?, ?, ?, ?, ?, ?, ?)",
        (user_id, req.username, hash_password(req.password), req.nickname, token, datetime.now().strftime("%Y-%m-%d"), now)
    )
    await db.commit()
    await db.close()
    response = JSONResponse({"success": True, "user_id": user_id, "nickname": req.nickname, "token": token})
    response.set_cookie("token", token, httponly=True, samesite="lax", max_age=30*24*3600)
    return response

@app.post("/api/auth/login")
async def login(req: LoginRequest):
    db = await get_db()
    cursor = await db.execute("SELECT * FROM users WHERE email = ?", (req.username,))
    user = await cursor.fetchone()
    if not user or user["password_hash"] != hash_password(req.password):
        await db.close()
        raise HTTPException(400, "账号或密码错误")
    token = str(uuid.uuid4())
    await db.execute("UPDATE users SET token = ? WHERE id = ?", (token, user["id"]))
    await db.commit()
    # Check agent application status
    agent_status = "none"
    cursor = await db.execute("SELECT status FROM agent_applications WHERE user_id = ?", (user["id"],))
    agent_row = await cursor.fetchone()
    if agent_row:
        agent_status = agent_row["status"]
    await db.close()
    # Check birthday
    birthday_blessing = None
    today_str = datetime.now().strftime("%m-%d")
    if user["birthday"]:
        try:
            bd = user["birthday"][5:]  # MM-DD
            if bd == today_str:
                birthday_blessing = f"生日快乐，{user['nickname']}！初眠AI祝你天天开心～"
        except Exception:
            pass
    response = JSONResponse({
        "success": True,
        "user_id": user["id"],
        "nickname": user["nickname"],
        "email": user["email"],
        "oobe_completed": bool(user["oobe_completed"]),
        "token": token,
        "birthday_blessing": birthday_blessing,
        "premium_points": user["premium_points"] or 0,
        "svip_type": user["svip_type"] or "none",
        "svip_expire": user["svip_expire"],
        "agent_status": agent_status,
        "github_bound": bool(user["github_id"])
    })
    response.set_cookie("token", token, httponly=True, samesite="lax", max_age=30*24*3600)
    return response

@app.post("/api/auth/logout")
async def logout(request: Request):
    user = request.state.user
    db = await get_db()
    await db.execute("UPDATE users SET token = NULL WHERE id = ?", (user["id"],))
    await db.commit()
    await db.close()
    response = JSONResponse({"success": True})
    response.delete_cookie("token")
    return response

@app.post("/api/auth/complete-oobe")
async def complete_oobe(request: Request):
    user = request.state.user
    db = await get_db()
    await db.execute("UPDATE users SET oobe_completed = 1 WHERE id = ?", (user["id"],))
    await db.commit()
    await db.close()
    return {"success": True}

@app.get("/api/user/info")
async def user_info(request: Request):
    user = request.state.user
    db = await get_db()
    cursor = await db.execute("SELECT COUNT(*) as c FROM followings WHERE following_id = ?", (user["id"],))
    followers = (await cursor.fetchone())["c"]
    cursor = await db.execute("SELECT COUNT(*) as c FROM followings WHERE follower_id = ?", (user["id"],))
    following = (await cursor.fetchone())["c"]
    cursor = await db.execute("SELECT COUNT(*) as c FROM followings f1 WHERE f1.follower_id = ? AND EXISTS (SELECT 1 FROM followings f2 WHERE f2.follower_id = f1.following_id AND f2.following_id = f1.follower_id)", (user["id"],))
    mutual = (await cursor.fetchone())["c"]
    cursor = await db.execute("SELECT COUNT(*) as c FROM notifications WHERE user_id = ? AND is_read = 0", (user["id"],))
    unread = (await cursor.fetchone())["c"]
    cursor = await db.execute("SELECT status FROM agent_applications WHERE user_id = ?", (user["id"],))
    agent_row = await cursor.fetchone()
    agent_status = agent_row["status"] if agent_row else "none"
    await db.close()
    return {
        "id": user["id"],
        "email": user["email"],
        "nickname": user["nickname"],
        "daily_points": user["daily_points"],
        "oobe_completed": bool(user["oobe_completed"]),
        "is_banned": bool(user["is_banned"]),
        "ban_until": user["ban_until"],
        "avatar": user["avatar"],
        "created_at": user["created_at"],
        "premium_points": user["premium_points"] or 0,
        "svip_type": user["svip_type"] or "none",
        "svip_expire": user["svip_expire"],
        "qq": user["qq"],
        "birthday": user["birthday"],
        "likes_count": user["likes_count"] or 0,
        "followers_count": followers,
        "following_count": following,
        "mutual_count": mutual,
        "unread_notifications": unread,
        "agent_status": agent_status,
        "github_id": user["github_id"]
    }

@app.get("/api/user/points-log")
async def points_log(request: Request):
    user = request.state.user
    db = await get_db()
    cursor = await db.execute("SELECT * FROM points_log WHERE user_id = ? ORDER BY created_at DESC LIMIT 50", (user["id"],))
    rows = await cursor.fetchall()
    await db.close()
    return [dict(r) for r in rows]

async def review_agent_application(reason: str) -> tuple:
    """调用GLM审核申请理由，返回(是否通过, 审核结果说明)。"""
    try:
        async with httpx.AsyncClient(timeout=30.0) as client:
            payload = {
                "model": "glm-4-flash",
                "messages": [
                    {"role": "system", "content": "你是一个严格的功能审核员。用户申请使用本地AGENT功能（AI操控手机）。请判断申请理由是否合理、是否有恶意用途。只回复JSON：{\"approved\": true/false, \"reason\": \"审核说明\"}"},
                    {"role": "user", "content": "申请理由：%s" % reason}
                ],
                "stream": False
            }
            headers = {"Authorization": "Bearer %s" % GLM_API_KEY, "Content-Type": "application/json"}
            resp = await client.post("%s/chat/completions" % GLM_BASE_URL, json=payload, headers=headers)
            data = resp.json()
            content = data["choices"][0]["message"]["content"]
            # 解析JSON
            import re as _re
            json_match = _re.search(r'\{[^{}]*\}', content)
            if json_match:
                result = json.loads(json_match.group())
                return (bool(result.get("approved", False)), result.get("reason", "审核完成"))
            return (True, "审核通过")
    except Exception as e:
        return (True, "自动审核通过（审核服务暂不可用，默认通过）")

class AgentApplyRequest(BaseModel):
    reason: str

@app.post("/api/agent/apply")
async def agent_apply(request: Request, req: AgentApplyRequest):
    user = request.state.user
    if not req.reason or len(req.reason.strip()) < 10:
        raise HTTPException(400, "申请理由至少10个字")
    db = await get_db()
    # 检查是否已有申请
    cursor = await db.execute("SELECT id, status FROM agent_applications WHERE user_id = ?", (user["id"],))
    existing = await cursor.fetchone()
    if existing and existing["status"] == "pending":
        await db.close()
        raise HTTPException(400, "您已有审核中的申请，请耐心等待")
    if existing and existing["status"] == "approved":
        await db.close()
        raise HTTPException(400, "您已通过审核，无需再次申请")
    app_id = str(uuid.uuid4())
    now = datetime.now().isoformat()
    if existing:
        await db.execute("UPDATE agent_applications SET reason = ?, status = 'pending', review_result = NULL, created_at = ?, reviewed_at = NULL WHERE id = ?",
                         (req.reason.strip(), now, existing["id"]))
    else:
        await db.execute("INSERT INTO agent_applications (id, user_id, reason, status, created_at) VALUES (?, ?, ?, 'pending', ?)",
                         (app_id, user["id"], req.reason.strip(), now))
    await db.commit()
    await db.close()
    # 异步触发审核（模拟3-4个工作日，这里立即审核但状态先pending，客户端显示审核中）
    # 实际审核由定时任务或下次查询时触发
    asyncio.create_task(_delayed_review(user["id"]))
    return {"success": True, "status": "pending", "message": "申请已提交，审核中（预计3-4个工作日）"}

async def _delayed_review(user_id: str):
    """延迟审核：等待60秒后自动审核（模拟工作日，实际可配置）。"""
    await asyncio.sleep(60)
    try:
        db = await get_db()
        cursor = await db.execute("SELECT id, reason, status FROM agent_applications WHERE user_id = ?", (user_id,))
        row = await cursor.fetchone()
        if row and row["status"] == "pending":
            approved, review_result = await review_agent_application(row["reason"])
            status = "approved" if approved else "rejected"
            await db.execute("UPDATE agent_applications SET status = ?, review_result = ?, reviewed_at = ? WHERE id = ?",
                             (status, review_result, datetime.now().isoformat(), row["id"]))
            await db.commit()
        await db.close()
    except Exception:
        pass

@app.get("/api/agent/apply/status")
async def agent_apply_status(request: Request):
    user = request.state.user
    db = await get_db()
    cursor = await db.execute("SELECT * FROM agent_applications WHERE user_id = ? ORDER BY created_at DESC LIMIT 1", (user["id"],))
    row = await cursor.fetchone()
    await db.close()
    if not row:
        return {"status": "none", "has_application": False}
    return {
        "status": row["status"],
        "reason": row["reason"],
        "review_result": row["review_result"],
        "created_at": row["created_at"],
        "reviewed_at": row["reviewed_at"],
        "has_application": True
    }

@app.post("/api/verify-app")
async def verify_app(req: VerifyAppRequest):
    official_packages = ["com.chumian.ai", "com.chumian.chumian_ai"]
    if req.package_name in official_packages:
        return {"valid": True, "message": "验证通过"}
    return {"valid": False, "message": "你使用的不是官方版"}

@app.get("/api/search")
async def search(request: Request, q: str):
    """联网搜索，实时获取实时返回，不存储结果。"""
    if not q or not q.strip():
        raise HTTPException(400, "搜索关键词不能为空")
    results = await web_search(q.strip(), max_results=10)
    return {"query": q, "results": results, "count": len(results)}

@app.post("/api/chat/stream")
async def chat_stream(request: Request, req: ChatRequest):
    user = request.state.user
    user_id = user["id"]
    model = req.model or "glm-4-flash"
    if model not in ALL_MODELS:
        raise HTTPException(400, "不支持的模型")
    is_violation, reason = await glm_moderate(req.message)
    if is_violation:
        db = await get_db()
        ban_days = random.randint(7, 14)
        ban_until = (datetime.now() + timedelta(days=ban_days)).isoformat()
        await db.execute("UPDATE users SET is_banned = 1, ban_until = ?, ban_reason = ? WHERE id = ?", (ban_until, reason, user_id))
        await db.commit()
        await db.close()
        raise HTTPException(403, "检测到违规内容，账号已被封禁至 %s" % ban_until)
    if model == IMAGE_MODEL:
        return await _handle_image_generation(user_id, req.message)
    if model == VIDEO_MODEL:
        return await _handle_video_generation(user_id, req.message)
    conv_id = req.conversation_id
    db = await get_db()
    if not conv_id:
        conv_id = str(uuid.uuid4())
        title = req.message[:20] + "..." if len(req.message) > 20 else req.message
        await db.execute(
            "INSERT INTO conversations (id, user_id, title, model, created_at) VALUES (?, ?, ?, ?, ?)",
            (conv_id, user_id, title, model, datetime.now().isoformat())
        )
        await db.commit()
    msg_id = str(uuid.uuid4())
    await db.execute(
        "INSERT INTO messages (id, conversation_id, role, content, created_at) VALUES (?, ?, ?, ?, ?)",
        (msg_id, conv_id, "user", req.message, datetime.now().isoformat())
    )
    await db.commit()
    cursor = await db.execute(
        "SELECT role, content, think_content FROM messages WHERE conversation_id = ? ORDER BY created_at",
        (conv_id,)
    )
    history_rows = await cursor.fetchall()
    history = [dict(r) for r in history_rows]
    await db.close()
    messages = [{"role": "system", "content": SYSTEM_PROMPT}]
    if req.agent_id:
        db = await get_db()
        cursor = await db.execute("SELECT system_prompt, opening_message FROM agents WHERE id = ?", (req.agent_id,))
        agent = await cursor.fetchone()
        await db.close()
        if agent and agent["system_prompt"]:
            messages.append({"role": "system", "content": agent["system_prompt"]})
    for h in history:
        content = h["content"]
        messages.append({"role": h["role"], "content": content})
    if req.image_url and model in VISION_MODELS:
        messages[-1]["content"] = [
            {"type": "text", "text": req.message},
            {"type": "image_url", "image_url": {"url": req.image_url}}
        ]
    # 联网搜索：AI提取关键词 -> 搜索 -> 拼入系统提示词
    search_results = []
    search_keyword = ""
    if req.web_search and model in TEXT_MODELS:
        search_keyword = await extract_search_keyword(req.message)
        print("联网搜索关键词:", search_keyword)
        if search_keyword and search_keyword.upper() != "NO_SEARCH":
            search_results = await web_search(search_keyword, max_results=5)
            if search_results:
                search_context = "\n\n【联网搜索结果】\n" + "\n".join(
                    ["[%d] %s\n%s\n来源: %s" % (i+1, r["title"], r["snippet"], r["url"]) for i, r in enumerate(search_results)]
                ) + "\n\n请结合以上搜索结果回答用户问题，回答中可引用来源编号。"
                messages[0]["content"] = SYSTEM_PROMPT + search_context
    async def generate():
        try:
            # 先发送搜索结果事件（含实际搜索关键词）
            if search_results:
                yield "data: %s\n\n" % json.dumps({"type": "search_results", "results": search_results, "keyword": search_keyword})
            async with httpx.AsyncClient(timeout=120.0) as client:
                payload = {"model": model, "messages": messages, "stream": True}
                headers = {"Authorization": "Bearer %s" % GLM_API_KEY, "Content-Type": "application/json"}
                full_content = ""
                think_content = ""
                tokens_used = 0
                async with client.stream("POST", "%s/chat/completions" % GLM_BASE_URL, json=payload, headers=headers) as resp:
                    async for line in resp.aiter_lines():
                        if line.startswith("data: "):
                            data_str = line[6:]
                            if data_str == "[DONE]":
                                break
                            try:
                                chunk = json.loads(data_str)
                                if "choices" in chunk and chunk["choices"]:
                                    delta = chunk["choices"][0].get("delta", {})
                                    reasoning = delta.get("reasoning_content", "")
                                    content = delta.get("content", "")
                                    if reasoning:
                                        think_content += reasoning
                                        yield "data: %s\n\n" % json.dumps({"type": "think", "content": reasoning})
                                    if content:
                                        full_content += content
                                        yield "data: %s\n\n" % json.dumps({"type": "content", "content": content})
                                if "usage" in chunk and chunk["usage"]:
                                    tokens_used = chunk["usage"].get("total_tokens", 0)
                            except Exception:
                                continue
                db = await get_db()
                ai_msg_id = str(uuid.uuid4())
                await db.execute(
                    "INSERT INTO messages (id, conversation_id, role, content, think_content, model, tokens_used, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
                    (ai_msg_id, conv_id, "assistant", full_content, think_content, model, tokens_used, datetime.now().isoformat())
                )
                await db.execute("UPDATE users SET daily_points = MAX(0, daily_points - ?) WHERE id = ?", (tokens_used, user_id))
                if tokens_used > 0:
                    await db.execute(
                        "INSERT INTO points_log (id, user_id, points, reason, created_at) VALUES (?, ?, ?, ?, ?)",
                        (str(uuid.uuid4()), user_id, -tokens_used, "对话消耗 %s" % model, datetime.now().isoformat())
                    )
                await db.commit()
                await db.close()
                yield "data: %s\n\n" % json.dumps({"type": "done", "conversation_id": conv_id, "tokens_used": tokens_used})
        except Exception as e:
            yield "data: %s\n\n" % json.dumps({"type": "error", "message": str(e)})
    return StreamingResponse(generate(), media_type="text/event-stream")

async def _handle_image_generation(user_id, prompt):
    async with httpx.AsyncClient(timeout=60.0) as client:
        payload = {"model": IMAGE_MODEL, "prompt": prompt, "size": "1024x1024"}
        headers = {"Authorization": "Bearer %s" % GLM_API_KEY}
        resp = await client.post("%s/images/generations" % GLM_BASE_URL, json=payload, headers=headers)
        data = resp.json()
        if "data" in data and data["data"]:
            img_url = data["data"][0].get("url")
            if img_url:
                img_resp = await client.get(img_url)
                filename = "img_%s.png" % str(uuid.uuid4())
                filepath = MEDIA_DIR / filename
                filepath.write_bytes(img_resp.content)
                db = await get_db()
                conv_id = str(uuid.uuid4())
                await db.execute("INSERT INTO conversations (id, user_id, title, model, created_at) VALUES (?, ?, ?, ?, ?)", (conv_id, user_id, prompt[:20], IMAGE_MODEL, datetime.now().isoformat()))
                await db.execute("INSERT INTO messages (id, conversation_id, role, content, created_at) VALUES (?, ?, ?, ?, ?)", (str(uuid.uuid4()), conv_id, "user", prompt, datetime.now().isoformat()))
                await db.execute("INSERT INTO messages (id, conversation_id, role, content, model, image_url, created_at) VALUES (?, ?, ?, ?, ?, ?, ?)", (str(uuid.uuid4()), conv_id, "assistant", "图片生成完成", IMAGE_MODEL, "/media/%s" % filename, datetime.now().isoformat()))
                await db.execute("UPDATE users SET daily_points = MAX(0, daily_points - 1000) WHERE id = ?", (user_id,))
                await db.commit()
                await db.close()
                def gen():
                    yield "data: %s\n\n" % json.dumps({"type": "content", "content": "图片生成完成！"})
                    yield "data: %s\n\n" % json.dumps({"type": "image", "url": "/media/%s" % filename})
                    yield "data: %s\n\n" % json.dumps({"type": "done", "conversation_id": conv_id})
                return StreamingResponse(gen(), media_type="text/event-stream")
    raise HTTPException(500, "图片生成失败")

async def _handle_video_generation(user_id, prompt):
    async with httpx.AsyncClient(timeout=60.0) as client:
        payload = {"model": VIDEO_MODEL, "prompt": prompt}
        headers = {"Authorization": "Bearer %s" % GLM_API_KEY}
        resp = await client.post("%s/videos/generations" % GLM_BASE_URL, json=payload, headers=headers)
        data = resp.json()
        if "id" in data:
            task_id = data["id"]
            video_tasks[task_id] = {"status": "processing", "prompt": prompt, "user_id": user_id}
            def gen():
                yield "data: %s\n\n" % json.dumps({"type": "content", "content": "视频生成任务已提交，正在处理中..."})
                yield "data: %s\n\n" % json.dumps({"type": "video_task", "task_id": task_id})
                yield "data: %s\n\n" % json.dumps({"type": "done"})
            return StreamingResponse(gen(), media_type="text/event-stream")
    raise HTTPException(500, "视频生成任务提交失败")

@app.get("/api/generate/video/{task_id}")
async def get_video_status(request: Request, task_id: str):
    if task_id not in video_tasks:
        raise HTTPException(404, "任务不存在")
    task = video_tasks[task_id]
    if task["status"] == "completed":
        return task
    async with httpx.AsyncClient(timeout=30.0) as client:
        headers = {"Authorization": "Bearer %s" % GLM_API_KEY}
        resp = await client.get("%s/async-result/%s" % (GLM_BASE_URL, task_id), headers=headers)
        data = resp.json()
        if data.get("task_status") == "SUCCESS":
            video_result = data.get("video_result", [])
            if video_result and len(video_result) > 0:
                video_url = video_result[0].get("url")
                if video_url:
                    video_resp = await client.get(video_url)
                    filename = "video_%s.mp4" % str(uuid.uuid4())
                    filepath = MEDIA_DIR / filename
                    filepath.write_bytes(video_resp.content)
                    task["status"] = "completed"
                    task["url"] = "/media/%s" % filename
                    db = await get_db()
                    await db.execute("UPDATE users SET daily_points = MAX(0, daily_points - 5000) WHERE id = ?", (task["user_id"],))
                    await db.commit()
                    await db.close()
        elif data.get("task_status") == "FAIL":
            task["status"] = "failed"
            task["error"] = data.get("message", "生成失败")
    return task

@app.get("/api/conversations")
async def list_conversations(request: Request):
    user = request.state.user
    db = await get_db()
    cursor = await db.execute(
        "SELECT id, title, model, created_at FROM conversations WHERE user_id = ? ORDER BY created_at DESC",
        (user["id"],)
    )
    rows = await cursor.fetchall()
    convs = [dict(r) for r in rows]
    await db.close()
    return convs

@app.get("/api/conversations/{conv_id}/messages")
async def get_messages(request: Request, conv_id: str):
    user = request.state.user
    db = await get_db()
    cursor = await db.execute(
        "SELECT * FROM messages WHERE conversation_id = ? ORDER BY created_at",
        (conv_id,)
    )
    rows = await cursor.fetchall()
    messages = [dict(r) for r in rows]
    await db.close()
    return messages

@app.delete("/api/conversations/{conv_id}")
async def delete_conversation(request: Request, conv_id: str):
    user = request.state.user
    db = await get_db()
    await db.execute("DELETE FROM messages WHERE conversation_id = ?", (conv_id,))
    await db.execute("DELETE FROM conversations WHERE id = ? AND user_id = ?", (conv_id, user["id"]))
    await db.commit()
    await db.close()
    return {"success": True}

@app.get("/media/{filename}")
async def serve_media(filename: str):
    filepath = MEDIA_DIR / filename
    if filepath.exists():
        return FileResponse(str(filepath))
    raise HTTPException(404, "文件不存在或已过期")

@app.get("/api/posts")
async def list_posts():
    db = await get_db()
    cursor = await db.execute("""
        SELECT p.*, u.nickname as author_nickname, u.avatar as author_avatar
        FROM posts p JOIN users u ON p.user_id = u.id
        WHERE p.approved = 1
        ORDER BY p.created_at DESC
    """)
    rows = await cursor.fetchall()
    posts = [dict(r) for r in rows]
    await db.close()
    return posts

@app.get("/api/posts/{post_id}")
async def get_post(post_id: str):
    db = await get_db()
    cursor = await db.execute("""
        SELECT p.*, u.nickname as author_nickname, u.avatar as author_avatar
        FROM posts p JOIN users u ON p.user_id = u.id
        WHERE p.id = ?
    """, (post_id,))
    post = await cursor.fetchone()
    await db.close()
    if not post:
        raise HTTPException(404, "帖子不存在")
    return dict(post)

@app.post("/api/posts")
async def create_post(request: Request, req: PostCreateRequest):
    user = request.state.user
    if req.type not in ("agent", "image", "video"):
        raise HTTPException(400, "仅支持发布智能体、图片、视频")
    is_violation, reason = await glm_moderate(req.title + " " + req.content)
    if is_violation:
        raise HTTPException(400, "内容包含违规信息，无法发布")
    db = await get_db()
    post_id = str(uuid.uuid4())
    await db.execute(
        "INSERT INTO posts (id, user_id, title, content, type, media_url, agent_id, approved, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, 1, ?)",
        (post_id, user["id"], req.title, req.content, req.type, req.media_url, req.agent_id, datetime.now().isoformat())
    )
    await db.commit()
    await db.close()
    return {"success": True, "post_id": post_id}

@app.post("/api/posts/{post_id}/like")
async def like_post(request: Request, post_id: str):
    user = request.state.user
    db = await get_db()
    cursor = await db.execute("SELECT id FROM post_likes WHERE post_id = ? AND user_id = ?", (post_id, user["id"]))
    existing = await cursor.fetchone()
    if existing:
        await db.execute("DELETE FROM post_likes WHERE post_id = ? AND user_id = ?", (post_id, user["id"]))
        await db.execute("UPDATE posts SET likes = likes - 1 WHERE id = ?", (post_id,))
        liked = False
    else:
        await db.execute(
            "INSERT INTO post_likes (id, post_id, user_id, created_at) VALUES (?, ?, ?, ?)",
            (str(uuid.uuid4()), post_id, user["id"], datetime.now().isoformat())
        )
        await db.execute("UPDATE posts SET likes = likes + 1 WHERE id = ?", (post_id,))
        liked = True
    await db.commit()
    await db.close()
    return {"liked": liked}

@app.get("/api/posts/{post_id}/comments")
async def list_comments(post_id: str):
    db = await get_db()
    cursor = await db.execute("""
        SELECT c.*, u.nickname as author_nickname, u.avatar as author_avatar
        FROM comments c JOIN users u ON c.user_id = u.id
        WHERE c.post_id = ?
        ORDER BY c.created_at ASC
    """, (post_id,))
    rows = await cursor.fetchall()
    comments = [dict(r) for r in rows]
    await db.close()
    return comments

@app.post("/api/posts/{post_id}/comments")
async def create_comment(request: Request, post_id: str, req: CommentCreateRequest):
    user = request.state.user
    is_violation, _ = await glm_moderate(req.content)
    if is_violation:
        raise HTTPException(400, "评论包含违规内容")
    db = await get_db()
    comment_id = str(uuid.uuid4())
    await db.execute(
        "INSERT INTO comments (id, post_id, user_id, content, created_at) VALUES (?, ?, ?, ?, ?)",
        (comment_id, post_id, user["id"], req.content, datetime.now().isoformat())
    )
    await db.execute("UPDATE posts SET comments_count = comments_count + 1 WHERE id = ?", (post_id,))
    await db.commit()
    await db.close()
    return {"success": True, "comment_id": comment_id}

@app.get("/api/agents")
async def list_agents():
    db = await get_db()
    cursor = await db.execute("""
        SELECT a.*, u.nickname as author_nickname
        FROM agents a JOIN users u ON a.user_id = u.id
        ORDER BY a.created_at DESC
    """)
    rows = await cursor.fetchall()
    agents = [dict(r) for r in rows]
    await db.close()
    return agents

@app.get("/api/health")
async def health():
    return {"status": "ok", "service": "chumian-ai"}

@app.get("/api/agents/leaderboard")
async def agent_leaderboard(limit: int = 50):
    db = await get_db()
    cursor = await db.execute("""
        SELECT a.*, u.nickname as author_nickname
        FROM agents a JOIN users u ON a.user_id = u.id
        WHERE a.is_published = 1
        ORDER BY a.likes DESC
        LIMIT ?
    """, (limit,))
    rows = await cursor.fetchall()
    await db.close()
    return [dict(r) for r in rows]

@app.get("/api/agents/{agent_id}")
async def get_agent(agent_id: str):
    db = await get_db()
    cursor = await db.execute("""
        SELECT a.*, u.nickname as author_nickname
        FROM agents a JOIN users u ON a.user_id = u.id
        WHERE a.id = ?
    """, (agent_id,))
    agent = await cursor.fetchone()
    await db.close()
    if not agent:
        raise HTTPException(404, "智能体不存在")
    return dict(agent)

@app.post("/api/agents")
async def create_agent(request: Request, req: AgentCreateRequest):
    user = request.state.user
    db = await get_db()
    agent_id = str(uuid.uuid4())
    await db.execute(
        "INSERT INTO agents (id, user_id, name, description, system_prompt, opening_message, avatar, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
        (agent_id, user["id"], req.name, req.description, req.system_prompt, req.opening_message, req.avatar, datetime.now().isoformat())
    )
    await db.commit()
    await db.close()
    return {"success": True, "agent_id": agent_id}

@app.post("/api/agents/{agent_id}")
async def update_agent(request: Request, agent_id: str, req: AgentCreateRequest):
    user = request.state.user
    db = await get_db()
    cursor = await db.execute("SELECT user_id FROM agents WHERE id = ?", (agent_id,))
    agent = await cursor.fetchone()
    if not agent or agent["user_id"] != user["id"]:
        await db.close()
        raise HTTPException(403, "无权修改此智能体")
    await db.execute(
        "UPDATE agents SET name = ?, description = ?, system_prompt = ?, opening_message = ?, avatar = ? WHERE id = ?",
        (req.name, req.description, req.system_prompt, req.opening_message, req.avatar, agent_id)
    )
    await db.commit()
    await db.close()
    return {"success": True}

@app.post("/api/agents/{agent_id}/clone")
async def clone_agent(request: Request, agent_id: str):
    user = request.state.user
    db = await get_db()
    cursor = await db.execute("SELECT * FROM agents WHERE id = ?", (agent_id,))
    agent = await cursor.fetchone()
    if not agent:
        await db.close()
        raise HTTPException(404, "智能体不存在")
    new_id = str(uuid.uuid4())
    await db.execute(
        "INSERT INTO agents (id, user_id, name, description, system_prompt, opening_message, avatar, created_at, likes, download_count, is_published) VALUES (?, ?, ?, ?, ?, ?, ?, ?, 0, 0, 0)",
        (new_id, user["id"], agent["name"], agent["description"], agent["system_prompt"], agent["opening_message"], agent["avatar"], datetime.now().isoformat())
    )
    await db.execute("UPDATE agents SET download_count = download_count + 1 WHERE id = ?", (agent_id,))
    await db.commit()
    await db.close()
    return {"success": True, "agent_id": new_id}

@app.post("/api/agents/{agent_id}/like")
async def like_agent(request: Request, agent_id: str):
    user = request.state.user
    db = await get_db()
    try:
        await db.execute("INSERT INTO agent_likes (id, agent_id, user_id, created_at) VALUES (?, ?, ?, ?)",
            (str(uuid.uuid4()), agent_id, user["id"], datetime.now().isoformat()))
        await db.execute("UPDATE agents SET likes = likes + 1 WHERE id = ?", (agent_id,))
        await db.commit()
        liked = True
    except Exception:
        await db.execute("DELETE FROM agent_likes WHERE agent_id = ? AND user_id = ?", (agent_id, user["id"]))
        await db.execute("UPDATE agents SET likes = MAX(likes - 1, 0) WHERE id = ?", (agent_id,))
        await db.commit()
        liked = False
    cursor = await db.execute("SELECT likes FROM agents WHERE id = ?", (agent_id,))
    row = await cursor.fetchone()
    await db.close()
    return {"success": True, "liked": liked, "likes": row["likes"] if row else 0}

@app.post("/api/agents/{agent_id}/publish")
async def publish_agent(request: Request, agent_id: str):
    user = request.state.user
    db = await get_db()
    cursor = await db.execute("SELECT * FROM agents WHERE id = ?", (agent_id,))
    agent = await cursor.fetchone()
    if not agent or agent["user_id"] != user["id"]:
        await db.close()
        raise HTTPException(403, "无权操作此智能体")
    is_violation, reason = await glm_moderate(agent["name"] + " " + (agent["description"] or "") + " " + (agent["system_prompt"] or ""))
    if is_violation:
        await db.close()
        raise HTTPException(400, "内容违规，无法发布: " + reason)
    await db.execute("UPDATE agents SET is_published = 1 WHERE id = ?", (agent_id,))
    await db.commit()
    await db.close()
    return {"success": True}

@app.get("/api/explore")
async def explore_list(type: str = "all", page: int = 1, page_size: int = 20):
    db = await get_db()
    offset = (page - 1) * page_size
    if type == "all":
        cursor = await db.execute("""
            SELECT p.*, u.nickname as author_nickname, a.name as agent_name, a.avatar as agent_avatar
            FROM posts p JOIN users u ON p.user_id = u.id
            LEFT JOIN agents a ON p.agent_id = a.id
            WHERE p.approved = 1 AND p.type IN ('agent','image','video')
            ORDER BY p.created_at DESC LIMIT ? OFFSET ?
        """, (page_size, offset))
    else:
        cursor = await db.execute("""
            SELECT p.*, u.nickname as author_nickname, a.name as agent_name, a.avatar as agent_avatar
            FROM posts p JOIN users u ON p.user_id = u.id
            LEFT JOIN agents a ON p.agent_id = a.id
            WHERE p.approved = 1 AND p.type = ?
            ORDER BY p.created_at DESC LIMIT ? OFFSET ?
        """, (type, page_size, offset))
    rows = await cursor.fetchall()
    await db.close()
    return [dict(r) for r in rows]

@app.get("/api/models")
async def list_models():
    return {
        "text": TEXT_MODELS,
        "vision": VISION_MODELS,
        "image": IMAGE_MODEL,
        "video": VIDEO_MODEL,
        "all": ALL_MODELS
    }

@app.get("/api/templates")
async def list_templates():
    return [
        {"id": "1", "name": "写一首诗", "prompt": "请以春天为主题写一首现代诗", "icon": "🎨", "category": "写作"},
        {"id": "2", "name": "代码助手", "prompt": "你是一个专业的程序员，请帮我解决编程问题", "icon": "💻", "category": "编程"},
        {"id": "3", "name": "故事创作", "prompt": "请帮我写一个科幻短篇故事", "icon": "📖", "category": "写作"},
        {"id": "4", "name": "翻译官", "prompt": "你是一个专业翻译，请帮我翻译以下内容", "icon": "🌐", "category": "工具"},
        {"id": "5", "name": "美食推荐", "prompt": "请推荐几道家常菜并给出做法", "icon": "🍳", "category": "生活"},
        {"id": "6", "name": "旅行规划", "prompt": "请帮我规划一次旅行", "icon": "✈️", "category": "生活"},
        {"id": "7", "name": "学习辅导", "prompt": "请帮我讲解这个知识点", "icon": "📚", "category": "学习"},
        {"id": "8", "name": "生成图片", "prompt": "[图片模式] 请描述你想要的图片", "icon": "🖼️", "category": "创作"},
        {"id": "9", "name": "生成视频", "prompt": "[视频模式] 请描述你想要的视频", "icon": "🎬", "category": "创作"},
        {"id": "10", "name": "周报生成", "prompt": "请帮我生成一份工作周报", "icon": "📝", "category": "办公"},
    ]

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=24512)

# ==================== v2.0 New APIs ====================

class ProfileUpdateRequest(BaseModel):
    nickname: Optional[str] = None
    avatar: Optional[str] = None
    qq: Optional[str] = None
    birthday: Optional[str] = None

class ExchangeRequest(BaseModel):
    amount: int  # premium points to exchange

class SvipRequest(BaseModel):
    plan: str  # monthly / yearly / lifetime

class GuessRequest(BaseModel):
    points: int
    choice: str  # big / small

@app.put("/api/profile")
async def update_profile(request: Request, req: ProfileUpdateRequest):
    user = request.state.user
    db = await get_db()
    fields, values = [], []
    if req.nickname: fields.append("nickname = ?"); values.append(req.nickname)
    if req.avatar is not None: fields.append("avatar = ?"); values.append(req.avatar)
    if req.qq is not None: fields.append("qq = ?"); values.append(req.qq)
    if req.birthday is not None: fields.append("birthday = ?"); values.append(req.birthday)
    if fields:
        values.append(user["id"])
        await db.execute(f"UPDATE users SET {', '.join(fields)} WHERE id = ?", values)
        await db.commit()
    await db.close()
    return {"success": True}

class AvatarUploadRequest(BaseModel):
    avatar: str  # base64 encoded image

@app.get("/api/version/check")
async def version_check():
    return {
        "min_version": "2.5.0",
        "latest_version": "3.0.0",
        "download_url": "https://aka.doubaocdn.com/s/3mnsONg4T6",
        "github_url": "https://github.com/chumianyi/chumian-ai-app/releases",
        "force_update": True,
    }


@app.post("/api/auth/github")
async def github_auth(request: Request):
    """用GitHub access_token获取用户信息，返回或创建账号。
    支持两种模式：
    1. access_token模式（推荐）：客户端已完成code→token交换，直接传access_token
    2. code模式（兼容）：服务端尝试交换code（需服务端能访问github.com）
    """
    body = await request.json()
    code = body.get("code", "")
    access_token = body.get("access_token", "")
    code_verifier = body.get("code_verifier", "")
    if not code and not access_token:
        return JSONResponse(status_code=400, content={"error": "缺少code或access_token"})
    try:
        async with httpx.AsyncClient(timeout=15.0) as client:
            # 如果只有code，尝试服务端交换（可能因网络不可达而失败）
            if not access_token and code:
                if not GITHUB_CLIENT_SECRET and not code_verifier:
                    return JSONResponse(status_code=500, content={"error": "服务端未配置GitHub Client Secret"})
                token_data_dict = {"client_id": GITHUB_CLIENT_ID, "code": code}
                if GITHUB_CLIENT_SECRET:
                    token_data_dict["client_secret"] = GITHUB_CLIENT_SECRET
                if code_verifier:
                    token_data_dict["code_verifier"] = code_verifier
                token_resp = await client.post(
                    "https://github.com/login/oauth/access_token",
                    data=token_data_dict,
                    headers={"Accept": "application/json"},
                )
                token_data = token_resp.json()
                access_token = token_data.get("access_token", "")
                if not access_token:
                    return JSONResponse(status_code=400, content={"error": "GitHub授权失败", "detail": token_data})
            # 获取用户信息（api.github.com服务端可达）
            user_resp = await client.get(
                "https://api.github.com/user",
                headers={"Authorization": f"token {access_token}"},
            )
            gh_user = user_resp.json()
        gh_id = str(gh_user.get("id", ""))
        gh_login = gh_user.get("login", "")
        gh_avatar = gh_user.get("avatar_url", "")
        if not gh_id:
            return JSONResponse(status_code=400, content={"error": "获取GitHub用户信息失败"})
        # 查找已绑定的账号
        db = await get_db()
        cursor = await db.execute("SELECT id, email, nickname, avatar FROM users WHERE github_id = ?", (gh_id,))
        row = await cursor.fetchone()
        if row:
            # 已绑定，直接登录
            user_id = row["id"]
            token = str(uuid.uuid4())
            await db.execute("UPDATE users SET token = ? WHERE id = ?", (token, user_id))
            await db.commit()
            await db.close()
            return {"token": token, "user_id": user_id, "nickname": row["nickname"], "avatar": row["avatar"], "is_new": False}
        else:
            await db.close()
            # 未绑定，返回GitHub信息让客户端设置用户名密码
            return {"need_register": True, "github_id": gh_id, "github_login": gh_login, "github_avatar": gh_avatar}
    except Exception as e:
        return JSONResponse(status_code=500, content={"error": str(e)})


@app.post("/api/auth/github/bind")
async def github_bind(request: Request):
    """绑定GitHub到已有账号或创建新账号。支持两种模式：
    1. 未登录：传 github_id + username + password + nickname 创建账号并绑定
    2. 已登录：传 code 直接绑定当前用户
    """
    body = await request.json()
    code = body.get("code", "")
    github_id = body.get("github_id", "")
    username = body.get("username", "").strip()
    password = body.get("password", "")
    nickname = body.get("nickname", "") or username
    avatar = body.get("avatar", "")

    # 模式2：已登录用户用code或access_token绑定
    access_token = body.get("access_token", "")
    if (code or access_token) and not github_id:
        token = request.headers.get("Authorization", "")
        if token.startswith("Bearer "):
            token = token[7:]
        else:
            token = request.cookies.get("token", "")
        user = await get_user_by_token(token)
        if not user:
            return JSONResponse(status_code=401, content={"error": "未登录"})
        code_verifier = body.get("code_verifier", "")
        try:
            async with httpx.AsyncClient(timeout=15.0) as client:
                # 如果只有code，尝试服务端交换
                if not access_token and code:
                    if not GITHUB_CLIENT_SECRET and not code_verifier:
                        return JSONResponse(status_code=500, content={"error": "服务端未配置GitHub Client Secret"})
                    token_data_dict = {"client_id": GITHUB_CLIENT_ID, "code": code}
                    if GITHUB_CLIENT_SECRET:
                        token_data_dict["client_secret"] = GITHUB_CLIENT_SECRET
                    if code_verifier:
                        token_data_dict["code_verifier"] = code_verifier
                    token_resp = await client.post(
                        "https://github.com/login/oauth/access_token",
                        data=token_data_dict,
                        headers={"Accept": "application/json"},
                    )
                    token_data = token_resp.json()
                    access_token = token_data.get("access_token", "")
                    if not access_token:
                        return JSONResponse(status_code=400, content={"error": "GitHub授权失败", "detail": token_data})
                user_resp = await client.get(
                    "https://api.github.com/user",
                    headers={"Authorization": f"token {access_token}"},
                )
                gh_user = user_resp.json()
            gh_id = str(gh_user.get("id", ""))
            gh_avatar = gh_user.get("avatar_url", "")
            if not gh_id:
                return JSONResponse(status_code=400, content={"error": "获取GitHub用户信息失败"})
            db = await get_db()
            await db.execute(
                "UPDATE users SET github_id = ?, avatar = COALESCE(NULLIF(?, ''), avatar) WHERE id = ?",
                (gh_id, gh_avatar, user["id"]),
            )
            await db.commit()
            await db.close()
            return {"success": True, "github_id": gh_id, "message": "绑定成功"}
        except Exception as e:
            return JSONResponse(status_code=500, content={"error": str(e)})

    # 模式1：未登录，用github_id + 账号密码注册并绑定
    if not github_id or not username or not password:
        return JSONResponse(status_code=400, content={"error": "参数不完整"})

    db = await get_db()
    # 检查账号是否存在（用email列）
    cursor = await db.execute("SELECT id FROM users WHERE email = ?", (username,))
    existing = await cursor.fetchone()
    if existing:
        # 绑定到已有账号
        user_id = existing["id"]
        await db.execute(
            "UPDATE users SET github_id = ?, avatar = COALESCE(NULLIF(?, ''), avatar) WHERE id = ?",
            (github_id, avatar, user_id),
        )
    else:
        # 创建新账号
        user_id = str(uuid.uuid4())
        token = str(uuid.uuid4())
        await db.execute(
            "INSERT INTO users (id, email, password_hash, nickname, avatar, github_id, token, last_reset, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
            (user_id, username, hash_password(password), nickname, avatar, github_id, token, datetime.now().strftime("%Y-%m-%d"), datetime.now().isoformat()),
        )
    await db.commit()
    # 重新获取token
    cursor = await db.execute("SELECT id, token, nickname, avatar FROM users WHERE id = ?", (user_id,))
    row = await cursor.fetchone()
    await db.close()
    return {"token": row["token"], "user_id": row["id"], "nickname": row["nickname"], "avatar": row["avatar"], "is_new": not existing}


@app.post("/api/generate/image")
async def generate_image(request: Request):
    user_id = await _auth_user(request)
    if not user_id:
        return JSONResponse(status_code=401, content={"error": "未登录"})
    body = await request.json()
    prompt = body.get("prompt", "").strip()
    if not prompt:
        return JSONResponse(status_code=400, content={"error": "请输入提示词"})
    try:
        result = await _handle_image_generation(user_id, prompt)
        return {"url": result}
    except Exception as e:
        return JSONResponse(status_code=500, content={"error": str(e)})


@app.post("/api/user/avatar")
async def upload_avatar(request: Request, req: AvatarUploadRequest):
    user = request.state.user
    import base64
    try:
        img_data = base64.b64decode(req.avatar)
    except Exception:
        raise HTTPException(400, "无效的图片数据")
    if len(img_data) > 200 * 1024:
        raise HTTPException(400, "图片过大")
    # Detect format
    ext = "png"
    if img_data[:3] == b'\xff\xd8\xff':
        ext = "jpg"
    elif img_data[:8] == b'\x89PNG\r\n\x1a\n':
        ext = "png"
    filename = f"avatar_{user['id']}_{int(time.time())}.{ext}"
    filepath = MEDIA_DIR / filename
    filepath.write_bytes(img_data)
    avatar_url = f"/media/{filename}"
    db = await get_db()
    await db.execute("UPDATE users SET avatar = ? WHERE id = ?", (avatar_url, user["id"]))
    await db.commit()
    await db.close()
    return {"success": True, "avatar_url": avatar_url}

@app.get("/api/users/{user_id}")
async def get_user_profile(request: Request, user_id: str):
    db = await get_db()
    cursor = await db.execute("SELECT id, email, nickname, avatar, qq, birthday, created_at, likes_count FROM users WHERE id = ?", (user_id,))
    u = await cursor.fetchone()
    if not u:
        await db.close()
        raise HTTPException(404, "用户不存在")
    cursor = await db.execute("SELECT COUNT(*) as c FROM followings WHERE following_id = ?", (user_id,))
    followers = (await cursor.fetchone())["c"]
    cursor = await db.execute("SELECT COUNT(*) as c FROM followings WHERE follower_id = ?", (user_id,))
    following = (await cursor.fetchone())["c"]
    # Check if current user follows this user
    is_following = False
    is_mutual = False
    if hasattr(request.state, 'user') and request.state.user:
        cur_id = request.state.user["id"]
        cursor = await db.execute("SELECT COUNT(*) as c FROM followings WHERE follower_id = ? AND following_id = ?", (cur_id, user_id))
        is_following = (await cursor.fetchone())["c"] > 0
        if is_following:
            cursor = await db.execute("SELECT COUNT(*) as c FROM followings WHERE follower_id = ? AND following_id = ?", (user_id, cur_id))
            is_mutual = (await cursor.fetchone())["c"] > 0
    await db.close()
    return {
        "user_id": u["id"],
        "nickname": u["nickname"],
        "avatar": u["avatar"],
        "qq": u["qq"],
        "birthday": u["birthday"],
        "created_at": u["created_at"],
        "likes_count": u["likes_count"] or 0,
        "followers_count": followers,
        "following_count": following,
        "is_following": is_following,
        "is_mutual": is_mutual
    }

@app.post("/api/users/{user_id}/follow")
async def follow_user(request: Request, user_id: str):
    user = request.state.user
    if user["id"] == user_id:
        raise HTTPException(400, "不能关注自己")
    db = await get_db()
    cursor = await db.execute("SELECT id FROM users WHERE id = ?", (user_id,))
    target = await cursor.fetchone()
    if not target:
        await db.close()
        raise HTTPException(404, "用户不存在")
    cursor = await db.execute("SELECT id FROM followings WHERE follower_id = ? AND following_id = ?", (user["id"], user_id))
    existing = await cursor.fetchone()
    if existing:
        await db.execute("DELETE FROM followings WHERE id = ?", (existing["id"],))
        is_following = False
    else:
        await db.execute("INSERT INTO followings (id, follower_id, following_id, created_at) VALUES (?, ?, ?, ?)",
            (str(uuid.uuid4()), user["id"], user_id, datetime.now().isoformat()))
        is_following = True
        # Check mutual and create notification
        cursor = await db.execute("SELECT COUNT(*) as c FROM followings WHERE follower_id = ? AND following_id = ?", (user_id, user["id"]))
        if (await cursor.fetchone())["c"] > 0:
            await db.execute("INSERT INTO notifications (id, user_id, type, title, content, created_at) VALUES (?, ?, ?, ?, ?, ?)",
                (str(uuid.uuid4()), user_id, "follow", "新的互相关注", f"{user['nickname']} 关注了你，你们已互相关注！", datetime.now().isoformat()))
        else:
            await db.execute("INSERT INTO notifications (id, user_id, type, title, content, created_at) VALUES (?, ?, ?, ?, ?, ?)",
                (str(uuid.uuid4()), user_id, "follow", "新粉丝", f"{user['nickname']} 关注了你", datetime.now().isoformat()))
    await db.commit()
    await db.close()
    return {"success": True, "is_following": is_following}

@app.get("/api/users/{user_id}/followers")
async def get_followers(request: Request, user_id: str):
    db = await get_db()
    cursor = await db.execute("""
        SELECT u.id, u.nickname, u.avatar FROM followings f
        JOIN users u ON u.id = f.follower_id
        WHERE f.following_id = ? ORDER BY f.created_at DESC
    """, (user_id,))
    rows = await cursor.fetchall()
    await db.close()
    return [dict(r) for r in rows]

@app.get("/api/users/{user_id}/following")
async def get_following(request: Request, user_id: str):
    db = await get_db()
    cursor = await db.execute("""
        SELECT u.id, u.nickname, u.avatar FROM followings f
        JOIN users u ON u.id = f.following_id
        WHERE f.follower_id = ? ORDER BY f.created_at DESC
    """, (user_id,))
    rows = await cursor.fetchall()
    await db.close()
    return [dict(r) for r in rows]

@app.get("/api/notifications")
async def get_notifications(request: Request):
    user = request.state.user
    db = await get_db()
    cursor = await db.execute("SELECT * FROM notifications WHERE user_id = ? ORDER BY created_at DESC LIMIT 50", (user["id"],))
    rows = await cursor.fetchall()
    await db.close()
    return [dict(r) for r in rows]

@app.post("/api/notifications/{nid}/read")
async def read_notification(request: Request, nid: str):
    user = request.state.user
    db = await get_db()
    await db.execute("UPDATE notifications SET is_read = 1 WHERE id = ? AND user_id = ?", (nid, user["id"]))
    await db.commit()
    await db.close()
    return {"success": True}

@app.post("/api/checkin")
async def checkin(request: Request):
    user = request.state.user
    today = datetime.now().strftime("%Y-%m-%d")
    db = await get_db()
    cursor = await db.execute("SELECT id FROM checkins WHERE user_id = ? AND checkin_date = ?", (user["id"], today))
    if await cursor.fetchone():
        await db.close()
        raise HTTPException(400, "今日已签到")
    # Calculate streak
    cursor = await db.execute("SELECT checkin_date, streak FROM checkins WHERE user_id = ? ORDER BY checkin_date DESC LIMIT 1", (user["id"],))
    last = await cursor.fetchone()
    streak = 1
    if last:
        last_date = datetime.strptime(last["checkin_date"], "%Y-%m-%d")
        if (datetime.now() - last_date).days == 1:
            streak = last["streak"] + 1
    # Random premium points 3-10, +bonus for 7-day streak
    import random
    points = random.randint(3, 10)
    if streak > 0 and streak % 7 == 0:
        points += 20  # weekly bonus
    await db.execute("INSERT INTO checkins (id, user_id, checkin_date, premium_points, streak, created_at) VALUES (?, ?, ?, ?, ?, ?)",
        (str(uuid.uuid4()), user["id"], today, points, streak, datetime.now().isoformat()))
    await db.execute("UPDATE users SET premium_points = premium_points + ? WHERE id = ?", (points, user["id"]))
    await db.execute("INSERT INTO points_log (id, user_id, points, reason, created_at) VALUES (?, ?, ?, ?, ?)",
        (str(uuid.uuid4()), user["id"], points, "每日签到", datetime.now().isoformat()))
    await db.commit()
    await db.close()
    return {"success": True, "premium_points": points, "streak": streak, "total_premium": (user["premium_points"] or 0) + points}

@app.get("/api/checkin/status")
async def checkin_status(request: Request):
    user = request.state.user
    today = datetime.now().strftime("%Y-%m-%d")
    db = await get_db()
    cursor = await db.execute("SELECT id FROM checkins WHERE user_id = ? AND checkin_date = ?", (user["id"], today))
    checked = await cursor.fetchone() is not None
    cursor = await db.execute("SELECT checkin_date, premium_points, streak FROM checkins WHERE user_id = ? ORDER BY checkin_date DESC LIMIT 30", (user["id"],))
    history = [dict(r) for r in await cursor.fetchall()]
    cursor = await db.execute("SELECT streak FROM checkins WHERE user_id = ? ORDER BY checkin_date DESC LIMIT 1", (user["id"],))
    last = await cursor.fetchone()
    await db.close()
    return {"checked_today": checked, "current_streak": last["streak"] if last else 0, "history": history}

@app.post("/api/shop/exchange")
async def exchange_points(request: Request, req: ExchangeRequest):
    user = request.state.user
    if req.amount <= 0:
        raise HTTPException(400, "数量无效")
    db = await get_db()
    cursor = await db.execute("SELECT premium_points FROM users WHERE id = ?", (user["id"],))
    current = (await cursor.fetchone())["premium_points"] or 0
    if current < req.amount:
        await db.close()
        raise HTTPException(400, "高级积分不足")
    normal_points = req.amount * 20000000  # 1 premium = 20M normal
    await db.execute("UPDATE users SET premium_points = premium_points - ?, daily_points = daily_points + ? WHERE id = ?",
        (req.amount, normal_points, user["id"]))
    await db.execute("INSERT INTO points_log (id, user_id, points, reason, created_at) VALUES (?, ?, ?, ?, ?)",
        (str(uuid.uuid4()), user["id"], normal_points, f"积分兑换({req.amount}高级积分)", datetime.now().isoformat()))
    await db.commit()
    await db.close()
    return {"success": True, "normal_points_added": normal_points, "premium_remaining": current - req.amount}

@app.post("/api/shop/svip")
async def buy_svip(request: Request, req: SvipRequest):
    user = request.state.user
    prices = {"monthly": 200, "yearly": 2000, "lifetime": 100000}
    if req.plan not in prices:
        raise HTTPException(400, "无效的套餐")
    cost = prices[req.plan]
    db = await get_db()
    cursor = await db.execute("SELECT premium_points, svip_type, svip_expire FROM users WHERE id = ?", (user["id"],))
    u = await cursor.fetchone()
    if (u["premium_points"] or 0) < cost:
        await db.close()
        raise HTTPException(400, "高级积分不足")
    # Calculate expire
    now = datetime.now()
    if req.plan == "lifetime":
        expire = "2099-12-31"
    elif req.plan == "yearly":
        expire = (now + timedelta(days=365)).strftime("%Y-%m-%d")
    else:
        expire = (now + timedelta(days=30)).strftime("%Y-%m-%d")
    await db.execute("UPDATE users SET premium_points = premium_points - ?, svip_type = ?, svip_expire = ? WHERE id = ?",
        (cost, req.plan, expire, user["id"]))
    await db.execute("INSERT INTO points_log (id, user_id, points, reason, created_at) VALUES (?, ?, ?, ?, ?)",
        (str(uuid.uuid4()), user["id"], -cost, f"购买SVIP({req.plan})", datetime.now().isoformat()))
    await db.commit()
    await db.close()
    return {"success": True, "svip_type": req.plan, "svip_expire": expire}

@app.post("/api/activity/guess")
async def activity_guess(request: Request, req: GuessRequest):
    user = request.state.user
    today = datetime.now().strftime("%Y-%m-%d")
    if req.choice not in ("big", "small"):
        raise HTTPException(400, "选择无效")
    if req.points <= 0:
        raise HTTPException(400, "押注积分无效")
    db = await get_db()
    cursor = await db.execute("SELECT id FROM activity_guess WHERE user_id = ? AND guess_date = ?", (user["id"], today))
    if await cursor.fetchone():
        await db.close()
        raise HTTPException(400, "今日已参与过猜大小")
    cursor = await db.execute("SELECT daily_points FROM users WHERE id = ?", (user["id"],))
    current_points = (await cursor.fetchone())["daily_points"]
    if current_points < req.points:
        await db.close()
        raise HTTPException(400, "积分不足")
    # Random result: big = 51-100, small = 1-50
    import random
    roll = random.randint(1, 100)
    result = "big" if roll > 50 else "small"
    won = result == req.choice
    points_change = req.points if won else -req.points
    await db.execute("UPDATE users SET daily_points = daily_points + ? WHERE id = ?", (points_change, user["id"]))
    await db.execute("INSERT INTO activity_guess (id, user_id, guess_date, bet_points, choice, result, won, points_change, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
        (str(uuid.uuid4()), user["id"], today, req.points, req.choice, result, 1 if won else 0, points_change, datetime.now().isoformat()))
    await db.execute("INSERT INTO points_log (id, user_id, points, reason, created_at) VALUES (?, ?, ?, ?, ?)",
        (str(uuid.uuid4()), user["id"], points_change, f"猜大小({'赢' if won else '输'})", datetime.now().isoformat()))
    await db.commit()
    await db.close()
    return {"success": True, "roll": roll, "result": result, "won": won, "points_change": points_change, "remaining_points": current_points + points_change}

@app.get("/api/activity/guess/status")
async def guess_status(request: Request):
    user = request.state.user
    today = datetime.now().strftime("%Y-%m-%d")
    db = await get_db()
    cursor = await db.execute("SELECT * FROM activity_guess WHERE user_id = ? AND guess_date = ?", (user["id"], today))
    today_record = await cursor.fetchone()
    cursor = await db.execute("SELECT * FROM activity_guess WHERE user_id = ? ORDER BY guess_date DESC LIMIT 10", (user["id"],))
    history = [dict(r) for r in await cursor.fetchall()]
    await db.close()
    return {"played_today": today_record is not None, "today_record": dict(today_record) if today_record else None, "history": history}
