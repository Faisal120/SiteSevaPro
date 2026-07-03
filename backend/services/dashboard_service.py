from datetime import datetime, timezone

from core import db

from repositories.dashboard_repository import dashboard_repository


class DashboardService:

    async def bootstrap(self, user: dict):

        contractor_id = user["id"]

        alerts = []

        active_sites = await db.sites.count_documents(
            {
                "contractor_id": contractor_id
            }
        )

        total_labours = await db.labours.count_documents(
            {
                "contractor_id": contractor_id
            }
        )

        pending_tasks = await db.site_tasks.count_documents(
            {
                "contractor_id": contractor_id,
                "completed": False,
            }
        )

        if pending_tasks:

            alerts.append(
                {
                    "type": "task",
                    "title": f"{pending_tasks} Pending Tasks",
                    "description": "Complete today's assigned work.",
                    "route": "/app/tasks",
                }
            )

        low_progress = await db.sites.count_documents(
            {
                "contractor_id": contractor_id,
                "progress": {
                    "$lt": 30
                },
            }
        )

        if low_progress:

            alerts.append(
                {
                    "type": "site",
                    "title": f"{low_progress} Sites Need Attention",
                    "description": "Progress is below expected.",
                    "route": "/app/sites",
                }
            )

        pipeline = [
            {
                "$match": {
                    "contractor_id": contractor_id
                }
            },
            {
                "$group": {
                    "_id": None,
                    "total": {
                        "$sum": "$amount"
                    },
                }
            },
        ]

        payment = await db.payments.aggregate(
            pipeline
        ).to_list(1)

        cash_flow = payment[0]["total"] if payment else 0

        recent_sites = await db.sites.find(
            {
                "contractor_id": contractor_id
            }
        ).sort(
            "created_at",
            -1,
        ).limit(5).to_list(5)

        today_tasks = await db.site_tasks.find(
            {
                "contractor_id": contractor_id,
                "completed": False,
            }
        ).limit(5).to_list(5)

        return {
            "profile": {
                "id": user["id"],
                "name": user["full_name"],
                "email": user["email"],
                "role": user["role"],
                "company": user.get("company_name"),
            },
            "stats": {
                "active_sites": active_sites,
                "labours": total_labours,
                "pending_tasks": pending_tasks,
                "cash_flow": cash_flow,
            },
            "recent_sites": recent_sites,
            "today_tasks": today_tasks,
            "notifications": [],
            "alerts": alerts,
            "weather": {
                "city": "Lucknow",
                "temp": 34,
                "condition": "Sunny",
            },
        }

    async def contractor_dashboard(
        self,
        user,
    ):

        company_id = user["company_id"]

        total_sites = await db.sites.count_documents(
            {
                "company_id": company_id
            }
        )

        completed_sites = await db.sites.count_documents(
            {
                "company_id": company_id,
                "status": "COMPLETED",
            }
        )

        active_sites = await db.sites.count_documents(
            {
                "company_id": company_id,
                "status": "ACTIVE",
            }
        )

        total_budget = 0

        async for site in db.sites.find(
            {
                "company_id": company_id
            }
        ):

            total_budget += site.get(
                "budget",
                0,
            )

        payments = 0

        async for payment in db.payments.find(
            {
                "company_id": company_id
            }
        ):

            payments += payment.get(
                "amount",
                0,
            )

        return {

            "overview": {

                "sites": total_sites,

                "completed_sites": completed_sites,

                "active_sites": active_sites,

                "total_budget": total_budget,

                "payments": payments,

            }

        }
        
    async def get_dashboard(
        self,
        user,
    ):

        company_id = user["company_id"]

        total_sites = await dashboard_repository.total_sites(
            company_id
        )

        active_sites = await dashboard_repository.active_sites(
            company_id
        )

        completed_sites = await dashboard_repository.completed_sites(
            company_id
        )

        total_labour = await dashboard_repository.total_labour(
            company_id
        )

        pending_tasks = await dashboard_repository.pending_tasks(
            company_id
        )

        completed_tasks = await dashboard_repository.completed_tasks(
            company_id
        )

        payments = await dashboard_repository.payment_summary(
            company_id
        )

        materials = await dashboard_repository.material_summary(
            company_id
        )

        attendance = await dashboard_repository.attendance_summary(
            company_id
        )

        financial = {

            "income": 0,

            "expense": 0,

            "profit": 0,

        }

        for item in payments:

            payment_type = item["_id"]

            amount = item["total"]

            if payment_type == "CLIENT_RECEIVED":

                financial["income"] += amount

            else:

                financial["expense"] += amount

        financial["profit"] = (

            financial["income"]

            - financial["expense"]

        )

        dashboard = {

            "overview": {

                "total_sites": total_sites,

                "active_sites": active_sites,

                "completed_sites": completed_sites,

                "total_labour": total_labour,

                "pending_tasks": pending_tasks,

                "completed_tasks": completed_tasks,

            },

            "financial": financial,

            "inventory": materials,

            "attendance": attendance,

        }

        return dashboard


dashboard_service = DashboardService()