from repositories.report_repository import report_repository

from core import (
    new_id,
    now_iso,
)
from services.access_control import require_site_access


class ReportService:

    async def list_reports(
        self,
        site_id,
        user,
    ):

        query = {"company_id": user["company_id"]}

        if user["role"] == "CONTRACTOR":

            pass

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

            await require_site_access(site_id, user)

            query["site_id"] = site_id

        return await report_repository.list(
            query
        )


    async def create_report(
        self,
        body,
        user,
    ):

        await require_site_access(body.site_id, user, write=True)

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

            user["company_id"],

        )

        return document


report_service = ReportService()
