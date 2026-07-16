"""
Design Transaction Repository
"""

import uuid

from datetime import datetime

from core import db


class DesignTransactionRepository:

    async def create(
        self,
        document: dict,
    ):

        document["id"] = str(uuid.uuid4())

        document["created_at"] = datetime.utcnow().isoformat()

        await db.design_transactions.insert_one(document)

        return document

    async def list(
        self,
        company_id: str,
    ):

        return await db.design_transactions.find(

            {
                "company_id": company_id,
            },

            {
                "_id": 0,
            },

        ).sort(

            "created_at",

            -1,

        ).to_list(1000)


design_transaction_repository = DesignTransactionRepository()