from fastapi import APIRouter, Depends

from core import (
    get_current_user,
    require_roles,
)

from models.payment import PaymentIn

from services.payment_service import payment_service


router = APIRouter(

    prefix="/api/payments",

    tags=["Payments"],

)


@router.get("")
async def list_payments(

    site_id: str | None = None,

    user=Depends(
        get_current_user
    ),

):

    return await payment_service.list_payments(

        site_id,

        user,

    )


@router.post("")
async def create_payment(

    body: PaymentIn,

    user=Depends(

        require_roles(
            "CONTRACTOR"
        )

    ),

):

    return await payment_service.create_payment(

        body,

        user,

    )