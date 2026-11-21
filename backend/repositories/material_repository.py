from core import db
from repositories.notification_repository import notification_repository
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

        db_document = document.copy()

        await db.materials.insert_one(db_document)

        return document


    async def get(
        self,
        material_id: str,
        company_id: str | None = None,
    ):

        query = {"id": material_id}
        if company_id:
            query["company_id"] = company_id

        return await db.materials.find_one(
            query,
            {
                "_id": 0
            }
        )


    async def update_stock(
        self,
        material_id: str,
        company_id: str,
        stock: float,
    ):

        await db.materials.update_one(
            {
                "id": material_id,
                "company_id": company_id,
            },
            {
                "$set": {
                    "stock": stock
                }
            }
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
        await notification_repository.create(document)


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
