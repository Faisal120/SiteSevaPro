from fastapi import APIRouter, Depends

from core.auth import (
    get_current_user,
    require_roles,
)

from models.report import DailyReportIn

from services.report_service import report_service


router = APIRouter(

    prefix="/api/reports",

    tags=["Reports"],

)


@router.get("")
async def list_reports(

    site_id: str | None = None,

    user=Depends(
        get_current_user
    ),

):

    return await report_service.list_reports(

        site_id,

        user,

    )


@router.post("")
async def create_report(

    body: DailyReportIn,

    user=Depends(

        require_roles(
            "CONTRACTOR",
            "SUPERVISOR",
        )

    ),

):

    return await report_service.create_report(

        body,

        user,

    )