from fastapi import APIRouter, Depends

from core import get_current_user

from models.branding import BrandingUpdate

from services.branding_service import (
    branding_service,
)

router = APIRouter(

    prefix="/api/branding",

    tags=["Branding"],

)


@router.get("")
async def branding(

    user=Depends(get_current_user),

):

    return await branding_service.get(

        user["company_id"]

    )


@router.put("")
async def update(

    body: BrandingUpdate,

    user=Depends(get_current_user),

):

    return await branding_service.update(

        user["company_id"],

        body,

    )