from fastapi import APIRouter, Depends

from core import get_current_user

from models.design import DesignCreate

from services.design_service import design_service

router = APIRouter(
    prefix="/api/design",
    tags=["Design Studio"],
)


@router.get("")
async def list_designs(

    user=Depends(get_current_user),

):

    return await design_service.list(
        user,
    )


@router.post("")
async def create_design(

    body: DesignCreate,

    user=Depends(get_current_user),

):

    return await design_service.create(
        user,
        body,
    )


@router.get("/{design_id}")
async def design(

    design_id: str,

    user=Depends(get_current_user),

):

    return await design_service.get(
        user,
        design_id,
    )


@router.delete("/{design_id}")
async def delete(

    design_id: str,

    user=Depends(get_current_user),

):

    return await design_service.delete(
        user,
        design_id,
    )