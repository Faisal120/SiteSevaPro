from fastapi import APIRouter

from fastapi import Depends

from core import get_current_user
from core import require_roles 

from services.labour_service import labour_service

from models.labour import LabourIn


router = APIRouter(

    prefix="/api/labour",

    tags=["Labour"]

)


@router.get("")

async def list_labour(

    site_id: str | None = None,

    user=Depends(

        get_current_user

    ),

):

    return await labour_service.list_labour(

        site_id,

        user,

    )
    
@router.post("")
async def create_labour(

    body: LabourIn,

    user=Depends(
        require_roles(
            "CONTRACTOR"
        )
    ),

):

    return await labour_service.create_labour(

        body,

        user,

    )
    
@router.delete(
    "/{labour_id}"
)
async def delete_labour(

    labour_id: str,

    user=Depends(
        require_roles(
            "CONTRACTOR"
        )
    ),

):

    return await labour_service.delete_labour(

        labour_id,

        user,

    )