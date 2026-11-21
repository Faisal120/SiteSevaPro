from fastapi import APIRouter, Depends

from core import (
    get_current_user,
    require_roles,
)

from models.wallet import (
    WalletSettlementIn,
)

from services.wallet_service import (
    wallet_service,
)

router = APIRouter(

    prefix="/api/wallet",

    tags=["Wallet"]

)


# =====================================================
# GET WALLET
# =====================================================

@router.get("/{labour_id}")
async def get_wallet(

    labour_id: str,

    user=Depends(
        get_current_user
    ),

):

    return await wallet_service.get_wallet(

        labour_id,

        user,

    )


# =====================================================
# GET LEDGER
# =====================================================

@router.get("/{labour_id}/ledger")
async def ledger(

    labour_id: str,

    user=Depends(
        get_current_user
    ),

):

    return await wallet_service.ledger_summary(

        labour_id,

        user,

    )


# =====================================================
# SETTLEMENT
# =====================================================

@router.post("/settle")
async def settle(

    body: WalletSettlementIn,

    user=Depends(

        require_roles(

            "CONTRACTOR"

        )

    ),

):

    return await wallet_service.settle_payment(

        body,

        user,

    )


# =====================================================
# PAYROLL
# =====================================================

@router.get("/payroll/{month}")
async def payroll(

    month: str,

    user=Depends(

        require_roles(

            "CONTRACTOR"

        )

    ),

):

    return await wallet_service.monthly_summary(

        month,

        user,

    )


# =====================================================
# GENERATE SINGLE PAYROLL
# =====================================================

@router.post("/payroll/{labour_id}/{month}")
async def generate_payroll(

    labour_id: str,

    month: str,

    user=Depends(

        require_roles(

            "CONTRACTOR"

        )

    ),

):

    return await wallet_service.generate_payroll(

        labour_id,

        month,

        user,

    )
