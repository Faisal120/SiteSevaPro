from fastapi import HTTPException

from repositories.payment_repository import payment_repository

from core import (
    new_id,
    now_iso,
)

from services.notification_service import (
    notification_service,
)
from services.access_control import require_site_access

class PaymentService:

    async def list_payments(
        self,
        site_id,
        user,
    ):

        query = {"company_id": user.get("company_id")}

        if user["role"] == "CONTRACTOR":

            pass

        elif user["role"] == "CLIENT":

            sites = await payment_repository.get_client_sites(
                user["email"],
                user["company_id"],
            )

            query["site_id"] = {
                "$in": [
                    site["id"]
                    for site in sites
                ]
            }

            query["type"] = "CLIENT_RECEIVED"

        elif user["role"] == "SUPERVISOR":

            query["site_id"] = {
                "$in": user.get(
                    "site_ids",
                    []
                )
            }

        else:
            raise HTTPException(status_code=403, detail="Forbidden")

        if site_id:

            await require_site_access(site_id, user)

            query["site_id"] = site_id

        return await payment_repository.list(
            query
        )


    async def create_payment(
        self,
        body,
        user,
    ):

        await require_site_access(body.site_id, user, write=True)

        document = {

            "id": new_id(),

            "company_id": user["company_id"],

            "created_by": user["id"],

            "created_at": now_iso(),

            **body.model_dump(),

        }

        await payment_repository.create(
            document
        )
        
        await notification_service.notify_payment(

            company_id=user["company_id"],

            site_id=body.site_id,

            amount=body.amount,

        )

        return document


payment_service = PaymentService()
