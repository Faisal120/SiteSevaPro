from fastapi import APIRouter, Depends

from core.auth import (
    get_current_user,
    require_roles,
)

from models.material import MaterialIn

from services.material_service import material_service

from models.material import MaterialTxnIn

router = APIRouter(
    prefix="/api/materials",
    tags=["Materials"],
)


@router.get("")
async def list_materials(

    site_id: str | None = None,

    user=Depends(
        get_current_user
    ),

):

    return await material_service.list_materials(
        site_id,
        user,
    )


@router.post("")
async def create_material(

    body: MaterialIn,

    user=Depends(
        require_roles(
            "CONTRACTOR",
            "SUPERVISOR",
        )
    ),

):

    return await material_service.create_material(
        body,
        user,
    )
    
@router.post("/transactions")
async def create_transaction(

    body: MaterialTxnIn,

    user=Depends(

        require_roles(

            "CONTRACTOR",

            "SUPERVISOR",

        )

    ),

):

    return await material_service.create_material_transaction(

        body,

        user,

    )
    
@router.get("/transactions")
async def list_transactions(

    site_id: str | None = None,

    user=Depends(
        get_current_user
    ),

):

    return await material_service.list_transactions(

        site_id,

        user,

    )