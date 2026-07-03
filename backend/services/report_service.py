from repositories.report_repository import report_repository

from core.utils import (
    new_id,
    now_iso,
)


class ReportService:

    async def list_reports(
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

        elif user["role"] == "CLIENT":

            query["site_id"] = {
                "$in": user.get(
                    "site_ids",
                    []
                )
            }

        if site_id:

            query["site_id"] = site_id

        return await report_repository.list(
            query
        )


    async def create_report(
        self,
        body,
        user,
    ):

        document = {

            "id": new_id(),

            "company_id": user["company_id"],

            "created_by": user["id"],

            "created_at": now_iso(),

            **body.model_dump(),

        }

        await report_repository.create(
            document
        )

        await report_repository.update_site_progress(

            body.site_id,

            body.progress,

        )

        return document


report_service = ReportService()