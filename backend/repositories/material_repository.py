from core.database import db
from services.notification_service import (
    notification_service,
)

class MaterialRepository:

    # -------------------------------
    # Materials
    # -------------------------------

    async def list(
        self,
        query: dict,
    ):

        return await (
            db.materials
            .find(
                query,
                {"_id": 0},
            )
            .sort(
                "created_at",
                -1,
            )
            .to_list(1000)
        )


    async def create(
        self,
        document: dict,
    ):

        await db.materials.insert_one(
            document
        )

        return document


    async def get(
        self,
        material_id: str,
    ):

        return await db.materials.find_one(
            {
                "id": material_id
            },
            {
                "_id": 0
            }
        )


    async def update_stock(
        self,
        material_id: str,
        stock: float,
    ):

        await db.materials.update_one(
            {
                "id": material_id
            },
            {
                "$set": {
                    "stock": stock
                }
            }
        )
        
        await notification_service.notify_low_stock(

            company_id=user["company_id"],

            material=material,

            stock=new_stock,

        )

    # ======================================================
    # Material Transactions
    # ======================================================

    async def create_transaction(
        self,
        document: dict,
    ):

        await db.material_txns.insert_one(
            document
        )

        return document


    async def create_notification(
        self,
        document: dict,
    ):

        await db.notifications.insert_one(
            document
        )


    async def create_payment(
        self,
        document: dict,
    ):

        await db.payments.insert_one(
            document
        )
        
    # ======================================================
    # Material Transaction History
    # ======================================================

    async def list_transactions(
        self,
        query: dict,
    ):

        return await (

            db.material_txns

            .find(
                query,
                {
                    "_id": 0
                }
            )

            .sort(
                "created_at",
                -1
            )

            .limit(500)

            .to_list(500)

        )
        
material_repository = MaterialRepository()