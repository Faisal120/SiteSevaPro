from core import db
from core import now_iso

class DashboardRepository:

    # --------------------------------------------------
    # Sites
    # --------------------------------------------------

    async def total_sites(self, company_id):

        return await db.sites.count_documents(
            {
                "company_id": company_id
            }
        )


    async def active_sites(self, company_id):

        return await db.sites.count_documents(
            {
                "company_id": company_id,
                "status": "ACTIVE"
            }
        )


    async def completed_sites(self, company_id):

        return await db.sites.count_documents(
            {
                "company_id": company_id,
                "status": "COMPLETED"
            }
        )


    # --------------------------------------------------
    # Labour
    # --------------------------------------------------

    async def total_labour(self, company_id):

        return await db.labour.count_documents(
            {
                "company_id": company_id
            }
        )


    # --------------------------------------------------
    # Tasks
    # --------------------------------------------------

    async def pending_tasks(self, company_id):

        return await db.site_tasks.count_documents(
            {
                "company_id": company_id,
                "completed": False
            }
        )


    async def completed_tasks(self, company_id):

        return await db.site_tasks.count_documents(
            {
                "company_id": company_id,
                "completed": True
            }
        )

    # =========================================================
    # PAYMENTS
    # =========================================================

    async def payment_summary(
        self,
        company_id: str,
    ):

        pipeline = [
            {
                "$match": {
                    "company_id": company_id
                }
            },
            {
                "$group": {
                    "_id": "$type",
                    "total": {
                        "$sum": "$amount"
                    }
                }
            }
        ]

        return await db.payments.aggregate(
            pipeline
        ).to_list(None)
        
        
    async def material_summary(
        self,
        company_id: str,
    ):

        total = await db.materials.count_documents(
            {
                "company_id": company_id
            }
        )

        low_stock = await db.materials.count_documents(
            {
                "company_id": company_id,
                "$expr": {
                    "$lte": [
                        "$stock",
                        "$low_stock_threshold"
                    ]
                }
            }
        )

        return {
            "total": total,
            "low_stock": low_stock,
        }
        
    async def attendance_summary(
        self,
        company_id: str,
    ):

        today = now_iso()[:10]

        records = await db.attendance.find(
            {
                "company_id": company_id,
                "date": today,
            },
            {
                "_id": 0
            }
        ).to_list(None)

        summary = {
            "PRESENT": 0,
            "HALF_DAY": 0,
            "ABSENT": 0,
            "LEAVE": 0,
        }

        for report in records:

            for entry in report["entries"]:

                summary[
                    entry["status"]
                ] += 1

        return summary
    


dashboard_repository = DashboardRepository()