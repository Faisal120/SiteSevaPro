"""
Design Wallet Repository
"""

from datetime import datetime

from core import db


class DesignWalletRepository:

    async def get(
        self,
        company_id: str,
    ):

        return await db.design_wallets.find_one(

            {
                "company_id": company_id,
            },

            {
                "_id": 0,
            },

        )

    async def create(
        self,
        document: dict,
    ):

        document["created_at"] = datetime.utcnow().isoformat()

        document["updated_at"] = datetime.utcnow().isoformat()

        await db.design_wallets.insert_one(document)

        return document

    async def update(
        self,
        company_id: str,
        payload: dict,
    ):

        payload["updated_at"] = datetime.utcnow().isoformat()

        await db.design_wallets.update_one(

            {
                "company_id": company_id,
            },

            {
                "$set": payload,
            },

        )

    async def add_credits(
        self,
        company_id: str,
        credits: int,
    ):

        await db.design_wallets.update_one(

            {
                "company_id": company_id,
            },

            {
                "$inc": {
                    "credits": credits,
                },

                "$set": {

                    "updated_at": datetime.utcnow().isoformat()

                }

            }

        )

    async def deduct_credits(
        self,
        company_id: str,
        credits: int,
    ):

        return await db.design_wallets.update_one(

            {
                "company_id": company_id,
                "credits": {"$gte": credits},
            },

            {
                "$inc": {

                    "credits": -credits,

                },

                "$set": {

                    "updated_at": datetime.utcnow().isoformat()

                }

            }

        )


design_wallet_repository = DesignWalletRepository()
