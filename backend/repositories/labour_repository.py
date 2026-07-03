from core.database import db


class LabourRepository:

    async def list(

        self,

        query,

    ):

        return await (

            db.labour

            .find(

                query,

                {

                    "_id":0

                }

            )

            .sort(

                "created_at",

                -1

            )

            .to_list(1000)

        )
        
    async def create(
        self,
        document: dict,
    ):
        await db.labour.insert_one(document)
        return document

    async def get(
        self,
        labour_id: str,
    ):
        return await db.labour.find_one(
            {
                "id": labour_id
            },
            {
                "_id": 0
            }
        )

    async def update(
        self,
        labour_id: str,
        payload: dict,
    ):
        return await db.labour.update_one(
            {
                "id": labour_id
            },
            {
                "$set": payload
            }
        )

    async def delete(
        self,
        labour_id: str,
        company_id: str,
    ):

        return await db.labour.delete_one(
            {
                "id": labour_id,
                "company_id": company_id,
            }
        )


labour_repository = LabourRepository()