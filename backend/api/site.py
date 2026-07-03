from fastapi import APIRouter
from fastapi import Depends

from services.site_service import site_service

from core.auth import get_current_user

from models.site import SiteIn

from models.site import SiteAssignmentIn

router = APIRouter(

    prefix="/api/sites",

    tags=["Sites"]

)


@router.get("")

async def list_sites(

    user=Depends(get_current_user),

):

    return await site_service.list_sites(

        user,

    )
    

@router.get(
    "/{site_id}"
)
async def get_site(

    site_id: str,

    user=Depends(
        get_current_user
    ),

):

    return await site_service.get_site(

        site_id,

        user,

    )
    
@router.delete(
    "/{site_id}"
)
async def delete_site(

    site_id: str,

    user=Depends(
        require_roles("CONTRACTOR")
    ),

):

    return await site_service.delete_site(

        site_id,

        user,

    )
    
@router.put(
    "/{site_id}"
)
async def update_site(

    site_id: str,

    body: SiteIn,

    user=Depends(
        require_roles("CONTRACTOR")
    ),

):

    return await site_service.update_site(

        site_id,

        body,

        user,

    )
    
@router.post(
    "/{site_id}/assign-supervisor"
)
async def assign_supervisor(

    site_id: str,

    body: SiteAssignmentIn,

    user=Depends(
        require_roles(
            "CONTRACTOR"
        )
    ),

):

    return await site_service.assign_supervisor(

        site_id,

        body,

        user,

    )
    
@router.post(
    "/{site_id}/assign-client"
)
async def assign_client(

    site_id: str,

    body: SiteAssignmentIn,

    user=Depends(
        require_roles(
            "CONTRACTOR"
        )
    ),

):

    return await site_service.assign_client(

        site_id,

        body,

        user,

    )
    
    
@router.post("")
async def create_site(
    body: SiteIn,
    user=Depends(
        require_roles("CONTRACTOR")
    ),
):
    return await site_service.create_site(
        body,
        user,
    )