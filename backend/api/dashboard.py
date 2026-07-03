from fastapi import APIRouter
from fastapi import Depends

from core.auth import get_current_user

from services.dashboard_service import dashboard_service

router = APIRouter(
    prefix="/api/dashboard",
    tags=["Dashboard"],
)


@router.get("/bootstrap")
async def bootstrap(
    user=Depends(get_current_user),
):
    return await dashboard_service.bootstrap(
        user
    )


@router.get("/contractor")
async def contractor_dashboard(
    user=Depends(get_current_user),
):
    return await dashboard_service.contractor_dashboard(
        user
    )
    
@router.get("")
async def dashboard(

    user=Depends(
        get_current_user
    ),

):

    return await dashboard_service.get_dashboard(
        user
    )