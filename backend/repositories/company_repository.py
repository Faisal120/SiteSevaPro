import uuid

from datetime import datetime

from core import db


class CompanyRepository:

    async def create(
        self,
        company: dict,
    ):

        db_document = company.copy()

        await db.companies.insert_one(
            db_document
        )

        return company

    async def get(
        self,
        company_id: str,
    ):

        return await db.companies.find_one(
            {
                "id": company_id
            },
            {
                "_id": 0
            }
        )

    async def update_owner(

        self,

        company_id: str,

        owner_id: str,

    ):

        await db.companies.update_one(

            {

                "id": company_id

            },

            {

                "$set": {

                    "owner_id": owner_id

                }

            },

        )

company_repository = CompanyRepository()