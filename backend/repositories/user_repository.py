from typing import Optional

from core import db


class UserRepository:

    # -----------------------------------------

    async def get_by_email(
        self,
        email: str,
    ) -> Optional[dict]:

        return await db.users.find_one(
            {
                "email": email.lower()
            },
            {
                "_id": 0
            }
        )

    # -----------------------------------------

    async def get_by_id(
        self,
        user_id: str,
    ) -> Optional[dict]:

        return await db.users.find_one(
            {
                "id": user_id
            },
            {
                "_id": 0
            }
        )

    # -----------------------------------------

    async def create(
        self,
        document: dict,
    ):

        await db.users.insert_one(document)

        return document

    # -----------------------------------------

    async def update(
        self,
        user_id: str,
        update: dict,
    ):

        await db.users.update_one(
            {
                "id": user_id
            },
            {
                "$set": update
            }
        )

    # -----------------------------------------

    async def exists(
        self,
        email: str,
    ) -> bool:

        user = await self.get_by_email(email)

        return user is not None

    # -----------------------------------------

    async def list_by_company(
        self,
        company_id: str,
    ):

        return await db.users.find(
            {
                "company_id": company_id
            },
            {
                "_id": 0
            }
        ).to_list(1000)

    # -----------------------------------------

    async def block(
        self,
        user_id: str,
    ):

        await self.update(
            user_id,
            {
                "blocked": True
            }
        )

    # -----------------------------------------

    async def unblock(
        self,
        user_id: str,
    ):

        await self.update(
            user_id,
            {
                "blocked": False
            }
        )


user_repository = UserRepository()