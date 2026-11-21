from typing import Literal

import jwt
from fastapi import APIRouter, Depends, WebSocket, WebSocketDisconnect
from pydantic import BaseModel, Field

from core import (
    db,
    decode_jwt,
    get_current_user,
)

from services.notification_service import (
    notification_service,
)
from services.notification_delivery import notification_delivery


class PushDeviceIn(BaseModel):
    token: str = Field(min_length=20, max_length=4096)
    platform: Literal["android", "ios", "macos", "windows", "linux", "web"]


class PushDeviceOut(BaseModel):
    token: str = Field(min_length=20, max_length=4096)

router = APIRouter(

    prefix="/api/notifications",

    tags=["Notifications"],

)


@router.post("/devices")
async def register_device(body: PushDeviceIn, user=Depends(get_current_user)):
    return await notification_service.register_device(body, user)


@router.post("/devices/unregister")
async def unregister_device(body: PushDeviceOut, user=Depends(get_current_user)):
    return await notification_service.unregister_device(body.token, user)


@router.websocket("/stream")
async def notifications_stream(websocket: WebSocket):
    authorization = websocket.headers.get("authorization", "")
    if not authorization.lower().startswith("bearer "):
        await websocket.close(code=4401, reason="Missing token")
        return
    try:
        payload = decode_jwt(authorization.split(" ", 1)[1])
        user = await db.users.find_one({"id": payload.get("sub")}, {"_id": 0})
        if not user or user.get("blocked"):
            raise ValueError("User unavailable")
    except (jwt.PyJWTError, ValueError):
        await websocket.close(code=4401, reason="Invalid token")
        return
    await notification_delivery.realtime.connect(websocket, user)
    try:
        while True:
            message = await websocket.receive_text()
            if message == "ping":
                await websocket.send_json({"event": "pong"})
    except WebSocketDisconnect:
        pass
    finally:
        await notification_delivery.realtime.disconnect(websocket)


# =====================================================
# LIST NOTIFICATIONS
# =====================================================

@router.get("")
async def list_notifications(

    user=Depends(
        get_current_user
    ),

):

    return await notification_service.list_notifications(

        user,

    )


# =====================================================
# UNREAD COUNT
# =====================================================

@router.get("/unread")
async def unread_count(

    user=Depends(
        get_current_user
    ),

):

    return await notification_service.unread_count(

        user,

    )


# =====================================================
# MARK READ
# =====================================================

@router.put("/{notification_id}/read")
async def mark_read(

    notification_id: str,

    user=Depends(
        get_current_user
    ),

):

    return await notification_service.mark_read(

        notification_id,

        user,

    )


# =====================================================
# MARK ALL READ
# =====================================================

@router.put("/read-all")
async def mark_all_read(

    user=Depends(
        get_current_user
    ),

):

    return await notification_service.mark_all_read(

        user,

    )


# =====================================================
# DELETE
# =====================================================

@router.delete("/{notification_id}")
async def delete_notification(

    notification_id: str,

    user=Depends(
        get_current_user
    ),

):

    return await notification_service.delete_notification(

        notification_id,

        user,

    )
