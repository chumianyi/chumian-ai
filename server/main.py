import asyncio
import json
import time
import uuid
import hashlib
import random
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
    public_paths = ["/api/auth/send-code", "/api/auth/register", "/api/auth/login", "/api/verify-app", "/media/", "/api/models", "/api/templates"]
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
    await db.close()
    response = JSONResponse({
        "success": True,
        "user_id": user["id"],
        "nickname": user["nickname"],
        "email": user["email"],
        "oobe_completed": bool(user["oobe_completed"]),
        "token": token
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
    return {
        "id": user["id"],
        "email": user["email"],
        "nickname": user["nickname"],
        "daily_points": user["daily_points"],
        "oobe_completed": bool(user["oobe_completed"]),
        "is_banned": bool(user["is_banned"]),
        "ban_until": user["ban_until"],
        "avatar": user["avatar"],
        "created_at": user["created_at"]
    }

@app.get("/api/user/points-log")
async def points_log(request: Request):
    user = request.state.user
    db = await get_db()
    cursor = await db.execute("SELECT * FROM points_log WHERE user_id = ? ORDER BY created_at DESC LIMIT 50", (user["id"],))
    rows = await cursor.fetchall()
    await db.close()
    return [dict(r) for r in rows]

@app.post("/api/verify-app")
async def verify_app(req: VerifyAppRequest):
    official_packages = ["com.chumian.ai", "com.chumian.chumian_ai"]
    if req.package_name in official_packages:
        return {"valid": True, "message": "验证通过"}
    return {"valid": False, "message": "你使用的不是官方版"}

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
    async def generate():
        try:
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
