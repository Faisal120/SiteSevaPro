from fastapi import APIRouter
from fastapi import Depends

from core import get_current_user, require_roles

from services.dashboard import dashboard_dispatcher
from services.dashboard.contractor_dashboard_service import contractor_dashboard_service

router = APIRouter(
    prefix="/api/dashboard",
    tags=["Dashboard"],
)


@router.get("/bootstrap")
async def bootstrap(

    user=Depends(
        get_current_user
    ),

):

    return await dashboard_dispatcher.bootstrap(
        user
    )


@router.get("/contractor")
async def contractor_dashboard(
    user=Depends(require_roles("CONTRACTOR")),
):
    return await contractor_dashboard_service.dashboard(
        user
    )
    
@router.get("")
async def dashboard(

    user=Depends(
        get_current_user
    ),

):

    return await dashboard_dispatcher.dashboard(
        user
    )
