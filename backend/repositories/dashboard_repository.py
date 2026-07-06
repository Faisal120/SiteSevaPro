from datetime import datetime, timedelta

from bson import ObjectId

from core import db


class DashboardRepository:

    async def get_sites(self, company_id):

        cursor = db.sites.find(
            {
                "company_id": company_id
            }
        )

        return await cursor.to_list(None)

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
                "status": {
                    "$in": [
                        "ACTIVE",
                        "IN_PROGRESS",
                        "RUNNING"
                    ]
                }
            }
        )

    async def completed_sites(self, company_id):

        return await db.sites.count_documents(
            {
                "company_id": company_id,
                "status": "COMPLETED"
            }
        )

    async def total_labour(self, company_id):

        return await db.labours.count_documents(
            {
                "company_id": company_id
            }
        )

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

    async def payment_summary(self, company_id):

        pipeline = [

            {
                "$match": {
                    "company_id": company_id
                }
            },

            {
                "$group": {

                    "_id": "$payment_type",

                    "total": {
                        "$sum": "$amount"
                    }

                }
            }

        ]

        return await db.payments.aggregate(
            pipeline
        ).to_list(None)

    async def material_summary(self, company_id):

        return await db.materials.find(
            {
                "company_id": company_id
            }
        ).to_list(None)

    async def attendance_summary(self, company_id):

        today = datetime.utcnow() - timedelta(days=30)

        pipeline = [

            {
                "$match": {

                    "company_id": company_id,

                    "date": {
                        "$gte": today
                    }

                }
            },

            {
                "$group": {

                    "_id": "$date",

                    "present": {

                        "$sum": {

                            "$cond": [

                                {
                                    "$eq": [
                                        "$status",
                                        "PRESENT"
                                    ]
                                },

                                1,

                                0

                            ]

                        }

                    },

                    "absent": {

                        "$sum": {

                            "$cond": [

                                {
                                    "$eq": [
                                        "$status",
                                        "ABSENT"
                                    ]
                                },

                                1,

                                0

                            ]

                        }

                    }

                }

            },

            {
                "$sort": {

                    "_id": 1

                }

            }

        ]

        return await db.attendance.aggregate(
            pipeline
        ).to_list(None)

    async def latest_reports(self, company_id):

        return await db.daily_reports.find(

            {
                "company_id": company_id
            }

        ).sort(

            "created_at",

            -1

        ).limit(

            20

        ).to_list(

            None

        )

    async def latest_payments(self, company_id):

        return await db.payments.find(

            {
                "company_id": company_id
            }

        ).sort(

            "created_at",

            -1

        ).limit(

            20

        ).to_list(

            None

        )

    async def team(self, company_id):

        return await db.users.find(

            {
                "company_id": company_id,

                "role": {

                    "$in": [

                        "SUPERVISOR",

                        "CLIENT"

                    ]

                }

            }

        ).to_list(

            None

        )


dashboard_repository = DashboardRepository()