from core import db
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

        db_document = document.copy()

        await db.payments.insert_one(db_document)

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