import os
from typing import Literal, Optional

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field

from core import db, get_current_user, new_id, now_iso, require_roles

from services.design_wallet_service import (
    design_wallet_service,
)
from services.outbound_notification_service import notify_credit_approval

router = APIRouter(

    prefix="/api/design-wallet",

    tags=["Design Wallet"],

)


# Credits are verified manually, like the existing UPI subscription flow.
# Keeping prices server-side prevents the browser from selecting its own amount.
CREDIT_PACKS = {
    "STARTER": {"credits": 50, "amount": 199},
    "BUILDER": {"credits": 150, "amount": 499},
    "STUDIO": {"credits": 350, "amount": 999},
}


class CreditPurchaseIn(BaseModel):
    pack: Literal["STARTER", "BUILDER", "STUDIO"]
    utr: str = Field(min_length=4, max_length=40)
    note: Optional[str] = Field(default=None, max_length=280)


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


@router.get("/purchase/config")
async def purchase_config(user=Depends(get_current_user)):
    return {
        "upi_id": os.environ.get("UPI_ID", "fk1571515@ybl"),
        "payee_name": "Site Seva Pro",
        "packs": CREDIT_PACKS,
    }


@router.post("/purchase/request")
async def request_purchase(
    body: CreditPurchaseIn,
    user=Depends(require_roles("CONTRACTOR")),
):
    pack = CREDIT_PACKS[body.pack]
    doc = {
        "id": new_id(),
        "company_id": user["company_id"],
        "user_id": user["id"],
        "user_email": user.get("email"),
        "company_name": user.get("company_name"),
        "pack": body.pack,
        "credits": pack["credits"],
        "amount": pack["amount"],
        "utr": body.utr,
        "note": body.note,
        "status": "PENDING",
        "created_at": now_iso(),
    }
    await db.design_credit_requests.insert_one(doc)
    await db.notifications.insert_one({
        "id": new_id(), "user_id": user["id"], "company_id": user["company_id"],
        "title": "Credit purchase submitted",
        "body": f"{pack['credits']} design credits are pending UPI verification.",
        "type": "WALLET", "read": False, "created_at": now_iso(),
    })
    return {key: value for key, value in doc.items() if key != "_id"}


@router.get("/purchase/my")
async def my_purchase_requests(user=Depends(require_roles("CONTRACTOR"))):
    return await db.design_credit_requests.find(
        {"company_id": user["company_id"]}, {"_id": 0}
    ).sort("created_at", -1).limit(30).to_list(30)


@router.get("/purchase/admin")
async def admin_purchase_requests(
    status: Optional[str] = None,
    user=Depends(require_roles("SUPER_ADMIN")),
):
    query = {"status": status} if status else {}
    return await db.design_credit_requests.find(query, {"_id": 0}).sort("created_at", -1).limit(300).to_list(300)


@router.post("/purchase/{request_id}/approve")
async def approve_purchase(
    request_id: str,
    user=Depends(require_roles("SUPER_ADMIN")),
):
    request = await db.design_credit_requests.find_one({"id": request_id}, {"_id": 0})
    if not request:
        raise HTTPException(404, "Credit request not found")
    if request["status"] != "PENDING":
        raise HTTPException(400, "Request has already been processed")
    await design_wallet_service.balance(request["company_id"])
    await design_wallet_service.add(request["company_id"], request["credits"], f"{request['pack']} UPI credit pack · UTR {request['utr']}")
    await db.design_credit_requests.update_one({"id": request_id}, {"$set": {"status": "APPROVED", "approved_at": now_iso(), "approved_by": user["id"]}})
    await db.notifications.insert_one({
        "id": new_id(), "user_id": request["user_id"], "company_id": request["company_id"],
        "title": "Design credits added",
        "body": f"{request['credits']} credits have been added to your Design Studio wallet.",
        "type": "WALLET", "read": False, "created_at": now_iso(),
    })
    delivery = await notify_credit_approval(request["user_id"], request["credits"])
    return {"ok": True, "whatsapp_delivery": delivery}


@router.post("/purchase/{request_id}/reject")
async def reject_purchase(
    request_id: str,
    user=Depends(require_roles("SUPER_ADMIN")),
):
    request = await db.design_credit_requests.find_one({"id": request_id}, {"_id": 0})
    if not request:
        raise HTTPException(404, "Credit request not found")
    if request["status"] != "PENDING":
        raise HTTPException(400, "Request has already been processed")
    await db.design_credit_requests.update_one({"id": request_id}, {"$set": {"status": "REJECTED", "rejected_at": now_iso(), "rejected_by": user["id"]}})
    await db.notifications.insert_one({
        "id": new_id(), "user_id": request["user_id"], "company_id": request["company_id"],
        "title": "Credit purchase needs attention",
        "body": "Your credit purchase could not be verified. Please contact support with your UTR.",
        "type": "WALLET", "read": False, "created_at": now_iso(),
    })
    return {"ok": True}
