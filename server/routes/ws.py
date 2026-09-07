"""
WebSocket 路由
支持：
- WS /api/ws/chat — 实时聊天 WebSocket
- WS /api/ws/notifications — 通知推送 WebSocket
"""
import json
import uuid
from typing import Optional

from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Query, status

from services.websocket_manager import websocket_manager
from auth import decode_access_token

router = APIRouter()


# ==========================================================================
# 实时聊天 WebSocket
# ==========================================================================

@router.websocket("/api/ws/chat")
async def chat_websocket(
    websocket: WebSocket,
    token: Optional[str] = Query(None),
    session_id: Optional[str] = Query(None),
):
    """
    实时聊天 WebSocket 连接
    客户端通过 query 参数传入 token 进行鉴权
    支持消息收发、心跳、房间管理
    """
    # 鉴权
    user_id = None
    if token:
        try:
            user_id = decode_access_token(token)
        except Exception:
            await websocket.close(code=status.WS_1008_POLICY_VIOLATION, reason="Invalid token")
            return

    if not user_id:
        await websocket.close(code=status.WS_1008_POLICY_VIOLATION, reason="Authentication required")
        return

    connection_id = uuid.uuid4().hex

    # 注册连接
    conn = await websocket_manager.connect(
        websocket=websocket,
        user_id=user_id,
        connection_id=connection_id,
        session_id=session_id,
    )

    # 如果指定了会话，自动加入房间
    if session_id:
        await websocket_manager.join_room(connection_id, f"chat_{session_id}")

    try:
        while True:
            # 接收消息
            raw_data = await websocket.receive_text()

            try:
                data = json.loads(raw_data)
            except json.JSONDecodeError:
                await websocket.send_json({
                    "type": "error",
                    "error": "Invalid JSON format",
                    "timestamp": __import__("datetime").datetime.now(
                        __import__("datetime").timezone.utc
                    ).isoformat(),
                })
                continue

            msg_type = data.get("type", "message")

            if msg_type == "ping":
                # 心跳响应
                websocket_manager.update_heartbeat(connection_id)
                await websocket.send_json({
                    "type": "pong",
                    "timestamp": __import__("datetime").datetime.now(
                        __import__("datetime").timezone.utc
                    ).isoformat(),
                })

            elif msg_type == "message":
                # 聊天消息：广播到会话房间
                content = data.get("content", "")
                target_session = data.get("session_id", session_id)

                if target_session:
                    room_id = f"chat_{target_session}"
                    await websocket_manager.send_to_room(room_id, {
                        "type": "message",
                        "message_id": uuid.uuid4().hex,
                        "user_id": user_id,
                        "content": content,
                        "session_id": target_session,
                        "timestamp": __import__("datetime").datetime.now(
                            __import__("datetime").timezone.utc
                        ).isoformat(),
                    })

            elif msg_type == "typing":
                # 正在输入状态
                target_session = data.get("session_id", session_id)
                if target_session:
                    room_id = f"chat_{target_session}"
                    await websocket_manager.send_to_room(room_id, {
                        "type": "typing",
                        "user_id": user_id,
                        "is_typing": data.get("is_typing", True),
                        "timestamp": __import__("datetime").datetime.now(
                            __import__("datetime").timezone.utc
                        ).isoformat(),
                    })

            elif msg_type == "join_room":
                # 加入房间
                room = data.get("room", "")
                if room:
                    await websocket_manager.join_room(connection_id, room)

            elif msg_type == "leave_room":
                # 离开房间
                room = data.get("room", "")
                if room:
                    await websocket_manager.leave_room(connection_id, room)

            elif msg_type == "read_receipt":
                # 已读回执
                target_session = data.get("session_id", session_id)
                message_id = data.get("message_id", "")
                if target_session:
                    room_id = f"chat_{target_session}"
                    await websocket_manager.send_to_room(room_id, {
                        "type": "read_receipt",
                        "user_id": user_id,
                        "message_id": message_id,
                        "timestamp": __import__("datetime").datetime.now(
                            __import__("datetime").timezone.utc
                        ).isoformat(),
                    })

            else:
                await websocket.send_json({
                    "type": "error",
                    "error": f"Unknown message type: {msg_type}",
                })

    except WebSocketDisconnect:
        await websocket_manager.disconnect(connection_id)
    except Exception:
        await websocket_manager.disconnect(connection_id)


# ==========================================================================
# 通知推送 WebSocket
# ==========================================================================

@router.websocket("/api/ws/notifications")
async def notifications_websocket(
    websocket: WebSocket,
    token: Optional[str] = Query(None),
):
    """
    通知推送 WebSocket 连接
    用于接收系统通知、消息提醒、活动推送等
    """
    # 鉴权
    user_id = None
    if token:
        try:
            user_id = decode_access_token(token)
        except Exception:
            await websocket.close(code=status.WS_1008_POLICY_VIOLATION, reason="Invalid token")
            return

    if not user_id:
        await websocket.close(code=status.WS_1008_POLICY_VIOLATION, reason="Authentication required")
        return

    connection_id = uuid.uuid4().hex

    # 注册连接并加入通知房间
    conn = await websocket_manager.connect(
        websocket=websocket,
        user_id=user_id,
        connection_id=connection_id,
    )
    await websocket_manager.join_room(connection_id, f"notifications_{user_id}")

    try:
        while True:
            raw_data = await websocket.receive_text()

            try:
                data = json.loads(raw_data)
            except json.JSONDecodeError:
                continue

            msg_type = data.get("type", "")

            if msg_type == "ping":
                websocket_manager.update_heartbeat(connection_id)
                await websocket.send_json({
                    "type": "pong",
                    "timestamp": __import__("datetime").datetime.now(
                        __import__("datetime").timezone.utc
                    ).isoformat(),
                })

            elif msg_type == "mark_read":
                # 标记通知已读
                notification_id = data.get("notification_id", "")
                await websocket_manager.send_to_user(user_id, {
                    "type": "notification_read",
                    "notification_id": notification_id,
                    "user_id": user_id,
                    "timestamp": __import__("datetime").datetime.now(
                        __import__("datetime").timezone.utc
                    ).isoformat(),
                })

    except WebSocketDisconnect:
        await websocket_manager.disconnect(connection_id)
    except Exception:
        await websocket_manager.disconnect(connection_id)


# ==========================================================================
# WebSocket 状态查询（HTTP 接口）
# ==========================================================================

@router.get("/api/ws/stats")
async def get_ws_stats():
    """获取 WebSocket 连接统计信息"""
    stats = websocket_manager.get_stats()
    return {"code": 0, "message": "success", "data": stats}
