from fastapi import HTTPException

from repositories.user_repository import user_repository


class UserService:

    async def get(
        self,
        user_id: str,
    ):

        user = await user_repository.get_by_id(
            user_id
        )

        if user is None:

            raise HTTPException(
                404,
                "User not found",
            )

        return user


    async def get_by_email(
        self,
        email: str,
    ):

        return await user_repository.get_by_email(
            email.lower()
        )


    async def create(
        self,
        document: dict,
    ):

        return await user_repository.create(
            document
        )


    async def update(
        self,
        user_id: str,
        update: dict,
    ):

        await user_repository.update(
            user_id,
            update,
        )


    async def block(
        self,
        user_id: str,
    ):

        await user_repository.block(
            user_id
        )


    async def unblock(
        self,
        user_id: str,
    ):

        await user_repository.unblock(
            user_id
        )


user_service = UserService()