from fastapi import HTTPException

from repositories.labour_repository import labour_repository

from core.utils import new_id, now_iso


class LabourService:

    async def list_labour(

        self,

        site_id,

        user,

    ):

        query = {}

        if user["role"] == "CONTRACTOR":

            query["company_id"] = user["company_id"]

        elif user["role"] == "SUPERVISOR":

            query["site_id"] = {

                "$in": user.get(

                    "site_ids",

                    []

                )

            }

        else:

            raise HTTPException(

                403,

                "Forbidden",

            )

        if site_id:

            query["site_id"] = site_id

        return await labour_repository.list(

            query

        )

    async def create_labour(
        self,
        body,
        user,
    ):

        document = body.model_dump()

        document["id"] = new_id()

        document["company_id"] = user["company_id"]

        document["created_by"] = user["id"]

        document["created_at"] = now_iso()

        document["active"] = True

        await labour_repository.create(
            document
        )

        return document
    
    # ============================================================
    # DELETE LABOUR
    # ============================================================

    async def delete_labour(
        self,
        labour_id: str,
        user,
    ):

        labour = await labour_repository.get(
            labour_id
        )

        if not labour:

            raise HTTPException(
                404,
                "Labour not found",
            )

        if labour["company_id"] != user["company_id"]:

            raise HTTPException(
                403,
                "Forbidden",
            )

        await labour_repository.delete(

            labour_id,

            user["company_id"],

        )

        return {

            "success": True,

            "message": "Labour deleted successfully",

        }


labour_service = LabourService()