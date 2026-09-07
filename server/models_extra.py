"""
额外 Pydantic 数据模型 - 服务端扩充模块专用
覆盖：AI写作、AI绘画、数据分析、反馈、推送、好友、成就、钱包、管理后台
"""
from typing import Optional, List, Any, Dict
from pydantic import BaseModel, Field
from datetime import datetime


# ===== 通用响应 =====
class ExtraBaseResponse(BaseModel):
    code: int = 0
    message: str = "success"
    data: Optional[Any] = None


# ===== AI 写作 =====
class WritingRequest(BaseModel):
    """创建写作任务请求"""
    writing_type: str = Field(..., description="写作类型：作文/论文/小说/文案/诗歌/总结/翻译")
    topic: str = Field(..., min_length=1, max_length=500, description="写作主题或原文")
    params: Optional[Dict[str, Any]] = Field(
        default_factory=dict,
        description="额外参数：字数/风格/语言/目标读者等"
    )


class WritingResponse(BaseModel):
    """写作任务响应"""
    task_id: str
    writing_type: str
    topic: str
    status: str  # pending / processing / completed / failed
    result: Optional[str] = None
    error: Optional[str] = None
    created_at: Optional[str] = None
    completed_at: Optional[str] = None


class WritingHistoryItem(BaseModel):
    """写作历史条目"""
    task_id: str
    writing_type: str
    topic: str
    status: str
    result_preview: Optional[str] = None
    created_at: Optional[str] = None


# ===== AI 绘画 =====
class ImageGenRequest(BaseModel):
    """创建绘画任务请求"""
    prompt: str = Field(..., min_length=1, max_length=1000, description="绘画提示词")
    style: str = Field(default="写实", description="风格：写实/动漫/油画/水彩/赛博朋克")
    size: str = Field(default="1024x1024", description="尺寸：512x512/768x768/1024x1024")
    negative_prompt: Optional[str] = Field(None, description="反向提示词")


class ImageGenResponse(BaseModel):
    """绘画任务响应"""
    task_id: str
    prompt: str
    style: str
    size: str
    status: str  # pending / processing / completed / failed
    image_url: Optional[str] = None
    error: Optional[str] = None
    created_at: Optional[str] = None
    completed_at: Optional[str] = None


# ===== 数据分析 =====
class AnalyticsEvent(BaseModel):
    """上报事件"""
    event_type: str = Field(..., description="事件类型：page_view/click/conversation/...")
    event_name: str = Field(..., description="事件名称")
    properties: Optional[Dict[str, Any]] = Field(default_factory=dict, description="事件属性")
    timestamp: Optional[str] = None


class AnalyticsBatchRequest(BaseModel):
    """批量上报"""
    events: List[AnalyticsEvent]


class AnalyticsSummary(BaseModel):
    """用户使用统计"""
    total_conversations: int = 0
    total_messages: int = 0
    points_consumed: int = 0
    active_days: int = 0
    writing_count: int = 0
    image_count: int = 0
    period: str = "all"


class AnalyticsTrendItem(BaseModel):
    """趋势数据点"""
    date: str
    conversations: int = 0
    messages: int = 0
    points: int = 0


# ===== 反馈 =====
class FeedbackRequest(BaseModel):
    """提交反馈请求"""
    feedback_type: str = Field(..., description="类型：bug/建议/投诉/其他")
    content: str = Field(..., min_length=1, max_length=2000, description="反馈内容")
    contact: Optional[str] = Field(None, max_length=200, description="联系方式")
    screenshot_url: Optional[str] = Field(None, description="截图URL")


class FeedbackResponse(BaseModel):
    """反馈响应"""
    id: str
    feedback_type: str
    content: str
    contact: Optional[str] = None
    screenshot_url: Optional[str] = None
    status: str  # pending / processing / resolved / closed
    reply: Optional[str] = None
    created_at: Optional[str] = None
    replied_at: Optional[str] = None


# ===== 推送 =====
class PushDevice(BaseModel):
    """推送设备注册"""
    device_token: str = Field(..., description="设备推送token")
    platform: str = Field(..., description="平台：android/ios/web")
    device_model: Optional[str] = None


class PushSettings(BaseModel):
    """推送设置"""
    enabled: bool = True
    message_push: bool = True
    system_push: bool = True
    marketing_push: bool = False


class PushSendRequest(BaseModel):
    """发送推送请求（管理员）"""
    user_id: Optional[str] = Field(None, description="目标用户ID，为空则广播")
    title: str = Field(..., max_length=100)
    body: str = Field(..., max_length=500)
    push_type: str = Field(default="system", description="类型：system/message/marketing")


# ===== 好友 =====
class FriendRequest(BaseModel):
    """发送好友请求"""
    target_user_id: str = Field(..., description="目标用户ID")
    message: Optional[str] = Field(None, max_length=200, description="验证消息")


class FriendInfo(BaseModel):
    """好友信息"""
    user_id: str
    nickname: Optional[str] = None
    avatar: Optional[str] = None
    added_at: Optional[str] = None


class FriendRequestItem(BaseModel):
    """好友请求条目"""
    id: str
    from_user_id: str
    from_nickname: Optional[str] = None
    from_avatar: Optional[str] = None
    message: Optional[str] = None
    status: str  # pending / accepted / rejected
    created_at: Optional[str] = None


# ===== 成就 =====
class Achievement(BaseModel):
    """成就定义"""
    id: str
    name: str
    description: str
    icon: Optional[str] = None
    category: str = "general"  # general/social/creative/explorer
    target_value: int = 1
    reward_points: int = 0
    reward_diamonds: int = 0


class UserAchievement(BaseModel):
    """用户成就状态"""
    achievement_id: str
    name: str
    description: str
    progress: float = 0.0  # 0.0 - 1.0
    current_value: int = 0
    target_value: int = 1
    unlocked: bool = False
    claimed: bool = False
    unlocked_at: Optional[str] = None


# ===== 钱包 =====
class Wallet(BaseModel):
    """钱包余额"""
    user_id: str
    points: int = 0
    diamonds: int = 0
    total_recharged: int = 0


class Transaction(BaseModel):
    """交易流水"""
    id: str
    user_id: str
    type: str  # recharge/consume/transfer_in/transfer_out/refund/achievement
    amount: int = 0
    currency: str = "points"  # points / diamonds
    description: Optional[str] = None
    balance_after: int = 0
    created_at: Optional[str] = None


class RechargeRequest(BaseModel):
    """充值请求"""
    amount: int = Field(..., gt=0, description="充值积分数量")
    currency: str = Field(default="points", description="points/diamonds")
    payment_method: str = Field(default="mock", description="支付方式")


class TransferRequest(BaseModel):
    """转账请求"""
    to_user_id: str = Field(..., description="接收方用户ID")
    amount: int = Field(..., gt=0, description="转账数量")
    currency: str = Field(default="points", description="points/diamonds")
    remark: Optional[str] = Field(None, max_length=200)


# ===== 管理后台 =====
class AdminStats(BaseModel):
    """平台统计"""
    total_users: int = 0
    active_users_today: int = 0
    total_messages: int = 0
    total_posts: int = 0
    pending_posts: int = 0
    total_conversations: int = 0
    banned_users: int = 0
    total_feedback: int = 0
    pending_feedback: int = 0


class AdminUserItem(BaseModel):
    """管理员视角用户条目"""
    id: str
    email: Optional[str] = None
    nickname: Optional[str] = None
    is_banned: int = 0
    ban_until: Optional[str] = None
    daily_points: int = 0
    vip_status: int = 0
    created_at: Optional[str] = None


class AdminLogItem(BaseModel):
    """系统日志条目"""
    id: str
    admin_id: str
    action: str
    target_type: Optional[str] = None
    target_id: Optional[str] = None
    detail: Optional[str] = None
    ip: Optional[str] = None
    created_at: Optional[str] = None
