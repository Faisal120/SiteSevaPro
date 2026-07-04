from fastapi import APIRouter, Depends

from core import (
    get_current_user,
)

from services.notification_service import (
    notification_service,
)

router = APIRouter(

    prefix="/api/notifications",

    tags=["Notifications"],

)


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