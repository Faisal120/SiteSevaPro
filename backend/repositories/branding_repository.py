"""
Branding Repository
"""

from datetime import datetime

from core import db


class BrandingRepository:

    async def get(
        self,
        company_id: str,
    ):

        return await db.branding.find_one(

            {
                "company_id": company_id,
            },

            {
                "_id": 0,
            },

        )

    async def save(
        self,
        company_id: str,
        payload: dict,
    ):

        payload["updated_at"] = datetime.utcnow().isoformat()

        await db.branding.update_one(

            {
                "company_id": company_id,
            },

            {
                "$set": payload,
            },

            upsert=True,

        )

        return await self.get(
            company_id
        )


branding_repository = BrandingRepository()