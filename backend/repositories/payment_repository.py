from core.database import db
from services.notification_service import (
    notification_service,
)

class PaymentRepository:

    async def list(
        self,
        query: dict,
    ):

        return await (

            db.payments

            .find(
                query,
                {
                    "_id": 0
                }
            )

            .sort(
                "date",
                -1
            )

            .limit(500)

            .to_list(500)

        )


    async def create(
        self,
        document: dict,
    ):

        await db.payments.insert_one(
            document
        )
        
        await notification_service.notify_payment(

            company_id=user["company_id"],

            site_id=body.site_id,

            amount=body.amount,

        )

        return document


    async def get_client_sites(
        self,
        email: str,
    ):

        return await db.sites.find(

            {
                "client_email": email
            },

            {
                "_id": 0,
                "id": 1,
            }

        ).to_list(100)


payment_repository = PaymentRepository()