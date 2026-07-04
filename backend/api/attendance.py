from fastapi import APIRouter
from fastapi import Depends

from core import (
    get_current_user,
    require_roles,
)

from models.attendance import AttendanceIn

from services.attendance_service import attendance_service

router = APIRouter(

    prefix="/api/attendance",

    tags=["Attendance"],

)


@router.post("")
async def mark_attendance(

    body: AttendanceIn,

    user=Depends(

        require_roles(

            "CONTRACTOR",

            "SUPERVISOR",

        )

    ),

):

    return await attendance_service.mark_attendance(

        body,

        user,

    )


@router.get("")
async def get_attendance(

    site_id: str,

    date: str | None = None,

    user=Depends(

        get_current_user

    ),

):

    return await attendance_service.get_attendance(

        site_id,

        date,

        user,

    )