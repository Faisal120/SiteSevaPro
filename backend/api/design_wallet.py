from fastapi import APIRouter, Depends, HTTPException

from core import db, get_current_user, require_roles

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


@router.post("/purchase/request")
async def request_purchase(_: dict = Depends(require_roles("CONTRACTOR"))):
    """Manual credit-pack purchases are retired; plan credits remain intact."""
    raise HTTPException(410, "Manual credit purchases have been retired. Subscription credits are applied after secure online checkout.")


@router.get("/purchase/my")
async def my_purchase_requests(user=Depends(require_roles("CONTRACTOR"))):
    return await db.design_credit_requests.find(
        {"company_id": user["company_id"]}, {"_id": 0, "utr": 0, "note": 0}
    ).sort("created_at", -1).limit(30).to_list(30)


@router.get("/purchase/admin")
async def admin_purchase_requests(
    status: str | None = None,
    user=Depends(require_roles("SUPER_ADMIN")),
):
    query = {"status": status} if status else {}
    return await db.design_credit_requests.find(query, {"_id": 0, "utr": 0, "note": 0}).sort("created_at", -1).limit(300).to_list(300)


@router.post("/purchase/{request_id}/approve")
async def approve_purchase(
    request_id: str,
    _: dict = Depends(require_roles("SUPER_ADMIN")),
):
    raise HTTPException(410, "Manual credit-request approval has been retired; historical requests are read-only.")


@router.post("/purchase/{request_id}/reject")
async def reject_purchase(
    request_id: str,
    _: dict = Depends(require_roles("SUPER_ADMIN")),
):
    raise HTTPException(410, "Manual credit-request approval has been retired; historical requests are read-only.")
