"""
Pydantic 数据模型 - 请求/响应 schema 定义
"""
from typing import Optional, List, Any
from pydantic import BaseModel, Field
from datetime import datetime


# ===== 通用响应 =====
class BaseResponse(BaseModel):
    code: int = 0
    message: str = "success"
    data: Optional[Any] = None


# ===== 用户相关 =====
class UserCreate(BaseModel):
    """注册请求"""
    email: str = Field(..., description="邮箱/用户名")
    password: str = Field(..., min_length=6, description="密码")
    nickname: Optional[str] = Field(None, description="昵称")


class UserLogin(BaseModel):
    """登录请求"""
    email: str
    password: str


class UserUpdate(BaseModel):
    """更新用户资料"""
    nickname: Optional[str] = None
    avatar: Optional[str] = None
    qq: Optional[str] = None
    birthday: Optional[str] = None


class UserResponse(BaseModel):
    """用户信息响应"""
    id: str
    email: Optional[str] = None
    nickname: Optional[str] = None
    avatar: Optional[str] = None
    daily_points: int = 0
    vip_status: int = 0
    oobe_completed: int = 0
    is_banned: int = 0
    created_at: Optional[str] = None


class TokenResponse(BaseModel):
    """Token 响应"""
    access_token: str
    token_type: str = "bearer"
    user_id: str
    nickname: Optional[str] = None
    oobe_completed: int = 0


# ===== 会话相关 =====
class ConversationCreate(BaseModel):
    """创建会话请求"""
    title: Optional[str] = "新对话"


class ConversationResponse(BaseModel):
    """会话响应"""
    id: str
    user_id: str
    title: str
    created_at: Optional[str] = None


class ConversationUpdate(BaseModel):
    """更新会话请求"""
    title: str


# ===== 消息/聊天相关 =====
class MessageResponse(BaseModel):
    """消息响应"""
    id: str
    conversation_id: str
    role: str
    content: str
    think_content: Optional[str] = None
    model: Optional[str] = None
    tokens_used: int = 0
    created_at: Optional[str] = None


class ChatRequest(BaseModel):
    """聊天请求"""
    conversation_id: Optional[str] = None
    message: str
    model: str = "glm-4-flash"
    image_url: Optional[str] = None
    agent_id: Optional[str] = None
    web_search: bool = False


class ChatStreamEvent(BaseModel):
    """SSE 流式事件"""
    type: str  # think / content / image / video_task / search_results / done / error
    data: Optional[Any] = None


# ===== 社区帖子相关 =====
class PostCreate(BaseModel):
    """创建帖子请求"""
    title: str
    content: str
    type: Optional[str] = "text"
    media_url: Optional[str] = None
    agent_id: Optional[str] = None


class PostResponse(BaseModel):
    """帖子响应"""
    id: str
    user_id: str
    title: str
    content: str
    type: str = "text"
    media_url: Optional[str] = None
    agent_id: Optional[str] = None
    likes: int = 0
    comments_count: int = 0
    approved: int = 0
    nickname: Optional[str] = None
    avatar: Optional[str] = None
    created_at: Optional[str] = None


class CommentCreate(BaseModel):
    """发表评论请求"""
    content: str


class CommentResponse(BaseModel):
    """评论响应"""
    id: str
    post_id: str
    user_id: str
    content: str
    nickname: Optional[str] = None
    avatar: Optional[str] = None
    created_at: Optional[str] = None


# ===== Agent 相关 =====
class AgentCreate(BaseModel):
    """创建 Agent 请求"""
    name: str
    description: Optional[str] = ""
    system_prompt: Optional[str] = ""
    avatar: Optional[str] = None
    opening_message: Optional[str] = "你好！有什么可以帮你的吗？"


class AgentResponse(BaseModel):
    """Agent 响应"""
    id: str
    user_id: str
    name: str
    description: Optional[str] = None
    system_prompt: Optional[str] = None
    avatar: Optional[str] = None
    opening_message: Optional[str] = None
    likes: int = 0
    is_published: int = 0
    nickname: Optional[str] = None
    created_at: Optional[str] = None


# ===== 积分商城相关 =====
class CheckinResponse(BaseModel):
    """签到响应"""
    points: int
    streak: int
    total_points: int


class ShopItem(BaseModel):
    """商品"""
    id: str
    name: str
    description: str
    price: int
    icon: Optional[str] = None
    type: str = "virtual"


class ExchangeRequest(BaseModel):
    """积分兑换请求"""
    item_id: str


# ===== 活动竞猜相关 =====
class GuessRequest(BaseModel):
    """竞猜请求"""
    question: str
    choice: str
    points: int = Field(..., gt=0)


class GuessResponse(BaseModel):
    """竞猜响应"""
    id: str
    question: str
    choice: str
    points: int
    result: Optional[str] = None
    settled: int = 0
    created_at: Optional[str] = None


# ===== 搜索相关 =====
class SearchRequest(BaseModel):
    """搜索请求"""
    q: str


class SearchResult(BaseModel):
    """搜索结果"""
    title: str
    snippet: str
    url: str
    source: Optional[str] = None


class SearchResponse(BaseModel):
    """搜索响应"""
    query: str
    results: List[SearchResult] = []


# ===== 通知相关 =====
class NotificationResponse(BaseModel):
    """通知响应"""
    id: str
    type: str
    title: str
    content: str
    is_read: int = 0
    created_at: Optional[str] = None


# ===== 法律文档相关 =====
class LegalResponse(BaseModel):
    """法律文档响应"""
    title: str
    content: str
    updated_at: str


# ===== 模型列表 =====
class ModelInfo(BaseModel):
    """模型信息"""
    id: str
    name: str
    description: str
    type: str  # chat / vision / image / video
    supports_stream: bool = True
