"""
WebSocket 连接管理 - WebSocketManager
功能：
- 连接管理：注册/注销 WebSocket 连接
- 房间/会话：按会话或房间分组连接
- 消息广播：向指定用户/房间/全体发送消息
- 心跳检测：定时检测连接存活状态
- 断线重连：支持客户端断线重连
- 在线状态：维护用户在线状态
"""
import asyncio
import json
import time
from typing import Dict, Any, Optional, Set, List
from datetime import datetime, timezone

from fastapi import WebSocket


class ConnectionInfo:
    """连接信息"""
    def __init__(
        self,
        websocket: WebSocket,
        user_id: str,
        connection_id: str,
        session_id: Optional[str] = None,
    ):
        self.websocket = websocket
        self.user_id = user_id
        self.connection_id = connection_id
        self.session_id = session_id
        self.connected_at = datetime.now(timezone.utc)
        self.last_heartbeat = time.time()
        self.rooms: Set[str] = set()


class WebSocketManager:
    """WebSocket 连接管理器"""

    def __init__(self):
        # 所有连接：connection_id -> ConnectionInfo
        self._connections: Dict[str, ConnectionInfo] = {}
        # 用户连接映射：user_id -> Set[connection_id]
        self._user_connections: Dict[str, Set[str]] = {}
        # 房间连接映射：room_id -> Set[connection_id]
        self._rooms: Dict[str, Set[str]] = {}
        # 心跳检测间隔（秒）
        self._heartbeat_interval = 30
        # 连接超时时间（秒）
        self._connection_timeout = 90
        # 心跳任务
        self._heartbeat_task: Optional[asyncio.Task] = None
        # 消息统计
        self._total_messages = 0
        self._total_connections = 0

    # ==========================================================================
    # 连接管理
    # ==========================================================================

    async def connect(
        self,
        websocket: WebSocket,
        user_id: str,
        connection_id: str,
        session_id: Optional[str] = None,
    ) -> ConnectionInfo:
        """注册新连接"""
        await websocket.accept()

        conn = ConnectionInfo(
            websocket=websocket,
            user_id=user_id,
            connection_id=connection_id,
            session_id=session_id,
        )

        self._connections[connection_id] = conn
        self._user_connections.setdefault(user_id, set()).add(connection_id)
        self._total_connections += 1

        # 启动心跳检测（首次连接时）
        if self._heartbeat_task is None:
            self._heartbeat_task = asyncio.create_task(self._heartbeat_loop())

        # 通知用户上线
        await self._send_to_user(
            user_id,
            {
                "type": "connection_established",
                "connection_id": connection_id,
                "user_id": user_id,
                "timestamp": datetime.now(timezone.utc).isoformat(),
            },
        )

        return conn

    async def disconnect(self, connection_id: str):
        """注销连接"""
        conn = self._connections.pop(connection_id, None)
        if not conn:
            return

        # 从用户映射移除
        user_conns = self._user_connections.get(conn.user_id)
        if user_conns:
            user_conns.discard(connection_id)
            if not user_conns:
                self._user_connections.pop(conn.user_id, None)

        # 从所有房间移除
        for room_id in conn.rooms:
            room_conns = self._rooms.get(room_id)
            if room_conns:
                room_conns.discard(connection_id)
                if not room_conns:
                    self._rooms.pop(room_id, None)

        # 通知用户下线（如果没有其他连接）
        if conn.user_id not in self._user_connections:
            await self._broadcast_system_message({
                "type": "user_offline",
                "user_id": conn.user_id,
                "timestamp": datetime.now(timezone.utc).isoformat(),
            })

    def get_connection(self, connection_id: str) -> Optional[ConnectionInfo]:
        """获取连接信息"""
        return self._connections.get(connection_id)

    def get_user_connections(self, user_id: str) -> List[ConnectionInfo]:
        """获取用户的所有连接"""
        conn_ids = self._user_connections.get(user_id, set())
        return [self._connections[cid] for cid in conn_ids if cid in self._connections]

    @property
    def connection_count(self) -> int:
        """当前连接数"""
        return len(self._connections)

    @property
    def online_users(self) -> int:
        """在线用户数"""
        return len(self._user_connections)

    @property
    def total_messages(self) -> int:
        """总消息数"""
        return self._total_messages

    # ==========================================================================
    # 房间管理
    # ==========================================================================

    async def join_room(self, connection_id: str, room_id: str):
        """加入房间"""
        conn = self._connections.get(connection_id)
        if not conn:
            return

        conn.rooms.add(room_id)
        self._rooms.setdefault(room_id, set()).add(connection_id)

        # 通知房间内其他用户
        await self._send_to_room_except(
            room_id,
            connection_id,
            {
                "type": "user_joined_room",
                "room_id": room_id,
                "user_id": conn.user_id,
                "timestamp": datetime.now(timezone.utc).isoformat(),
            },
        )

    async def leave_room(self, connection_id: str, room_id: str):
        """离开房间"""
        conn = self._connections.get(connection_id)
        if not conn:
            return

        conn.rooms.discard(room_id)
        room_conns = self._rooms.get(room_id)
        if room_conns:
            room_conns.discard(connection_id)
            if not room_conns:
                self._rooms.pop(room_id, None)

    def get_room_members(self, room_id: str) -> List[str]:
        """获取房间内的用户 ID 列表"""
        conn_ids = self._rooms.get(room_id, set())
        user_ids = set()
        for cid in conn_ids:
            conn = self._connections.get(cid)
            if conn:
                user_ids.add(conn.user_id)
        return list(user_ids)

    def get_room_count(self, room_id: str) -> int:
        """获取房间内连接数"""
        return len(self._rooms.get(room_id, set()))

    @property
    def room_count(self) -> int:
        """房间总数"""
        return len(self._rooms)

    # ==========================================================================
    # 消息发送
    # ==========================================================================

    async def send_to_user(
        self,
        user_id: str,
        message: Dict[str, Any],
    ) -> int:
        """向指定用户的所有连接发送消息"""
        return await self._send_to_user(user_id, message)

    async def _send_to_user(
        self,
        user_id: str,
        message: Dict[str, Any],
    ) -> int:
        conn_ids = self._user_connections.get(user_id, set())
        sent = 0
        for cid in list(conn_ids):
            conn = self._connections.get(cid)
            if conn:
                try:
                    await conn.websocket.send_json(message)
                    sent += 1
                    self._total_messages += 1
                except Exception:
                    await self.disconnect(cid)
        return sent

    async def send_to_room(
        self,
        room_id: str,
        message: Dict[str, Any],
    ) -> int:
        """向房间内所有连接发送消息"""
        conn_ids = self._rooms.get(room_id, set())
        sent = 0
        for cid in list(conn_ids):
            conn = self._connections.get(cid)
            if conn:
                try:
                    await conn.websocket.send_json(message)
                    sent += 1
                    self._total_messages += 1
                except Exception:
                    await self.disconnect(cid)
        return sent

    async def _send_to_room_except(
        self,
        room_id: str,
        except_connection_id: str,
        message: Dict[str, Any],
    ):
        """向房间内除指定连接外的所有连接发送消息"""
        conn_ids = self._rooms.get(room_id, set())
        for cid in list(conn_ids):
            if cid == except_connection_id:
                continue
            conn = self._connections.get(cid)
            if conn:
                try:
                    await conn.websocket.send_json(message)
                    self._total_messages += 1
                except Exception:
                    await self.disconnect(cid)

    async def broadcast(self, message: Dict[str, Any]) -> int:
        """向所有连接广播消息"""
        sent = 0
        for cid in list(self._connections.keys()):
            conn = self._connections.get(cid)
            if conn:
                try:
                    await conn.websocket.send_json(message)
                    sent += 1
                    self._total_messages += 1
                except Exception:
                    await self.disconnect(cid)
        return sent

    async def _broadcast_system_message(self, message: Dict[str, Any]):
        """广播系统消息"""
        message["system"] = True
        await self.broadcast(message)

    async def send_to_connection(
        self,
        connection_id: str,
        message: Dict[str, Any],
    ) -> bool:
        """向单个连接发送消息"""
        conn = self._connections.get(connection_id)
        if not conn:
            return False
        try:
            await conn.websocket.send_json(message)
            self._total_messages += 1
            return True
        except Exception:
            await self.disconnect(connection_id)
            return False

    # ==========================================================================
    # 心跳检测
    # ==========================================================================

    def update_heartbeat(self, connection_id: str):
        """更新连接的心跳时间"""
        conn = self._connections.get(connection_id)
        if conn:
            conn.last_heartbeat = time.time()

    async def _heartbeat_loop(self):
        """心跳检测循环"""
        while True:
            await asyncio.sleep(self._heartbeat_interval)
            now = time.time()
            stale_connections = []

            for cid, conn in self._connections.items():
                if now - conn.last_heartbeat > self._connection_timeout:
                    stale_connections.append(cid)

            for cid in stale_connections:
                await self.disconnect(cid)

            # 如果没有连接了，停止心跳任务
            if not self._connections:
                self._heartbeat_task = None
                break

    # ==========================================================================
    # 在线状态
    # ==========================================================================

    def is_user_online(self, user_id: str) -> bool:
        """检查用户是否在线"""
        return user_id in self._user_connections

    def get_online_user_ids(self) -> List[str]:
        """获取所有在线用户 ID"""
        return list(self._user_connections.keys())

    def get_user_connection_count(self, user_id: str) -> int:
        """获取用户的连接数（多设备）"""
        return len(self._user_connections.get(user_id, set()))

    # ==========================================================================
    # 统计信息
    # ==========================================================================

    def get_stats(self) -> Dict[str, Any]:
        """获取连接统计信息"""
        return {
            "total_connections": self.connection_count,
            "online_users": self.online_users,
            "active_rooms": self.room_count,
            "total_messages_sent": self._total_messages,
            "total_connections_ever": self._total_connections,
            "heartbeat_interval": self._heartbeat_interval,
            "connection_timeout": self._connection_timeout,
        }

    async def shutdown(self):
        """关闭所有连接"""
        for cid in list(self._connections.keys()):
            conn = self._connections.get(cid)
            if conn:
                try:
                    await conn.websocket.close(code=1001, reason="Server shutdown")
                except Exception:
                    pass
        self._connections.clear()
        self._user_connections.clear()
        self._rooms.clear()
        if self._heartbeat_task:
            self._heartbeat_task.cancel()
            self._heartbeat_task = None


# 全局单例
websocket_manager = WebSocketManager()
