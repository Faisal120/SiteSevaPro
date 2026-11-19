"""
Design Repository

MongoDB Operations Only

SiteSeva Pro
"""

import uuid

from datetime import datetime

from core import db


class DesignRepository:

    # ==========================================
    # CREATE
    # ==========================================

    async def create(
    self,
    document: dict,
):
        document["id"] = str(uuid.uuid4())
        document["created_at"] = datetime.utcnow().isoformat()
        document["updated_at"] = datetime.utcnow().isoformat()

        await db.designs.insert_one(document)

        return await db.designs.find_one(
            {"id": document["id"]},
            {"_id": 0},
        )

    # ==========================================
    # GET
    # ==========================================

    async def get_by_id(
        self,
        design_id: str,
        company_id: str,
    ):

        return await db.designs.find_one(

            {
                "id": design_id,
                "company_id": company_id,
            },

            {
                "_id": 0,
            },

        )

    # ==========================================
    # LIST
    # ==========================================

    async def list(
        self,
        company_id: str,
    ):

        return await db.designs.find(

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

    # ==========================================
    # UPDATE
    # ==========================================

    async def update(
    self,
    design_id,
    values,
):

        await db.designs.update_one(
            {"id": design_id},
            {"$set": values},
        )

        return await db.designs.find_one(
            {"id": design_id},
            {"_id": 0},
        )

    # ==========================================
    # DELETE
    # ==========================================

    async def delete(
        self,
        design_id: str,
        company_id: str,
    ):

        await db.designs.delete_one(

            {
                "id": design_id,
                "company_id": company_id,
            }

        )

    # ==========================================
    # COUNT
    # ==========================================

    async def count(
        self,
        company_id: str,
    ):

        return await db.designs.count_documents(

            {
                "company_id": company_id,
            }

        )


design_repository = DesignRepository()