from fastapi import APIRouter, Depends

from core import get_current_user

from services.design_wallet_service import (
    design_wallet_service,
)

router = APIRouter(

    prefix="/api/design-wallet",

    tags=["Design Wallet"],

)


@router.get("")
async def wallet(

    user=Depends(get_current_user),

):

    return await design_wallet_service.balance(

        user["company_id"]

    )


@router.get("/transactions")
async def transactions(

    user=Depends(get_current_user),

):

    return await design_wallet_service.transactions(

        user["company_id"]

    )