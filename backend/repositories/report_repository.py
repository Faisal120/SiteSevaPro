from core import db


class ReportRepository:

    async def list(
        self,
        query: dict,
    ):

        return await (
            db.daily_reports
            .find(
                query,
                {"_id": 0},
            )
            .sort(
                "date",
                -1,
            )
            .limit(365)
            .to_list(365)
        )


    async def create(
        self,
        document: dict,
    ):

        await db.daily_reports.insert_one(
            document
        )

        return document


    async def update_site_progress(
        self,
        site_id: str,
        progress: int,
    ):

        await db.sites.update_one(
            {
                "id": site_id
            },
            {
                "$set": {
                    "progress": progress
                }
            }
        )


report_repository = ReportRepository()