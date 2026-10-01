from __future__ import annotations

from collections import defaultdict
from typing import Any

from fastapi import WebSocket


class RealtimeManager:
    def __init__(self) -> None:
        self.connections: dict[str, set[WebSocket]] = defaultdict(set)

    async def connect(
        self,
        websocket: WebSocket,
        channel: str,
    ) -> None:
        await websocket.accept()
        self.connections[channel].add(websocket)

    def disconnect(
        self,
        websocket: WebSocket,
        channel: str,
    ) -> None:
        if channel in self.connections:
            self.connections[channel].discard(websocket)

            if not self.connections[channel]:
                del self.connections[channel]

    async def send_to_channel(
        self,
        channel: str,
        message: dict[str, Any],
    ) -> None:
        connections = list(self.connections.get(channel, set()))

        disconnected: list[WebSocket] = []

        for websocket in connections:
            try:
                await websocket.send_json(message)
            except Exception:
                disconnected.append(websocket)

        for websocket in disconnected:
            self.disconnect(websocket, channel)

    async def broadcast(
        self,
        message: dict[str, Any],
    ) -> None:
        channels = list(self.connections.keys())

        for channel in channels:
            await self.send_to_channel(channel, message)

    def connection_count(self, channel: str | None = None) -> int:
        if channel is not None:
            return len(self.connections.get(channel, set()))

        return sum(
            len(connections)
            for connections in self.connections.values()
        )


realtime_manager = RealtimeManager()
