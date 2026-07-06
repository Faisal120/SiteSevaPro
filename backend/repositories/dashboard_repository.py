"""
Dashboard Repository

MongoDB Operations Only

Production Ready
SiteSeva Pro
"""

from datetime import datetime, timedelta

from core import db


class DashboardRepository:

    # =====================================================
    # COMPANY
    # =====================================================

    async def company(
        self,
        company_id: str,
    ):

        return await db.companies.find_one(
            {
                "id": company_id,
            },
            {
                "_id": 0,
            },
        )

    # =====================================================
    # SITES
    # =====================================================

    async def get_sites(
        self,
        company_id: str,
        role: str = "CONTRACTOR",
        user_id: str | None = None,
    ):

        query = {
            "company_id": company_id,
        }

        if role == "SUPERVISOR":

            query["supervisor_ids"] = user_id

        elif role == "CLIENT":

            query["client_ids"] = user_id

        return await (
            db.sites.find(
                query,
                {
                    "_id": 0,
                },
            )
            .sort(
                "created_at",
                -1,
            )
            .to_list(1000)
        )

    async def total_sites(
        self,
        company_id: str,
        role: str = "CONTRACTOR",
        user_id: str | None = None,
    ):

        query = {
            "company_id": company_id,
        }

        if role == "SUPERVISOR":

            query["supervisor_ids"] = user_id

        elif role == "CLIENT":

            query["client_ids"] = user_id

        return await db.sites.count_documents(
            query
        )

    async def active_sites(
        self,
        company_id: str,
        role: str = "CONTRACTOR",
        user_id: str | None = None,
    ):

        query = {

            "company_id": company_id,

            "status": {
                "$in": [
                    "ACTIVE",
                    "RUNNING",
                    "IN_PROGRESS",
                ]
            }

        }

        if role == "SUPERVISOR":

            query["supervisor_ids"] = user_id

        elif role == "CLIENT":

            query["client_ids"] = user_id

        return await db.sites.count_documents(
            query
        )

    async def completed_sites(
        self,
        company_id: str,
        role: str = "CONTRACTOR",
        user_id: str | None = None,
    ):

        query = {

            "company_id": company_id,

            "status": "COMPLETED",

        }

        if role == "SUPERVISOR":

            query["supervisor_ids"] = user_id

        elif role == "CLIENT":

            query["client_ids"] = user_id

        return await db.sites.count_documents(
            query
        )

    # =====================================================
    # TEAM
    # =====================================================

    async def get_team(
        self,
        company_id: str,
    ):

        return await (
            db.users.find(
                {
                    "company_id": company_id,

                    "role": {
                        "$in": [
                            "SUPERVISOR",
                            "CLIENT",
                        ]
                    },
                },
                {
                    "_id": 0,
                    "password": 0,
                },
            )
            .sort(
                "full_name",
                1,
            )
            .to_list(500)
        )

    async def supervisors(
        self,
        company_id: str,
    ):

        return await db.users.count_documents(
            {
                "company_id": company_id,
                "role": "SUPERVISOR",
            }
        )

    async def clients(
        self,
        company_id: str,
    ):

        return await db.users.count_documents(
            {
                "company_id": company_id,
                "role": "CLIENT",
            }
        )

    # =====================================================
    # LABOURS
    # =====================================================

    async def total_labours(
        self,
        company_id: str,
    ):

        return await db.labours.count_documents(
            {
                "company_id": company_id,
            }
        )

    async def todays_labours(
        self,
        company_id: str,
    ):

        today = datetime.utcnow().strftime("%Y-%m-%d")

        return await db.attendance.count_documents(
            {
                "company_id": company_id,
                "date": today,
                "status": "PRESENT",
            }
        )
        
        
            # =====================================================
    # DAILY REPORTS
    # =====================================================

    async def latest_reports(
        self,
        company_id: str,
        limit: int = 20,
    ):

        return await (
            db.daily_reports.find(
                {
                    "company_id": company_id,
                },
                {
                    "_id": 0,
                },
            )
            .sort(
                "created_at",
                -1,
            )
            .limit(limit)
            .to_list(limit)
        )

    async def todays_reports(
        self,
        company_id: str,
    ):

        today = datetime.utcnow().strftime("%Y-%m-%d")

        return await db.daily_reports.count_documents(
            {
                "company_id": company_id,
                "date": today,
            }
        )

    async def latest_photos(
        self,
        company_id: str,
        limit: int = 8,
    ):

        reports = await (
            db.daily_reports.find(
                {
                    "company_id": company_id,
                    "media_urls.0": {
                        "$exists": True,
                    },
                },
                {
                    "_id": 0,
                },
            )
            .sort(
                "created_at",
                -1,
            )
            .limit(50)
            .to_list(50)
        )

        photos = []

        for report in reports:

            for media in report.get(
                "media_urls",
                [],
            ):

                if media.get("type") != "image":
                    continue

                photos.append(
                    {
                        "site_id": report.get("site_id"),
                        "site_name": report.get("site_name"),
                        "url": media.get("url"),
                        "caption": media.get("caption"),
                        "uploaded_by": report.get("created_by"),
                        "report_date": report.get("date"),
                        "created_at": report.get("created_at"),
                    }
                )

        return photos[:limit]

    # =====================================================
    # PAYMENTS
    # =====================================================

    async def payments(
        self,
        company_id: str,
        limit: int | None = None,
    ):

        cursor = db.payments.find(
            {
                "company_id": company_id,
            },
            {
                "_id": 0,
            },
        ).sort(
            "created_at",
            -1,
        )

        if limit:
            cursor = cursor.limit(limit)

        return await cursor.to_list(limit or 1000)

    async def payment_summary(
        self,
        company_id: str,
    ):

        pipeline = [

            {
                "$match": {
                    "company_id": company_id,
                }
            },

            {
                "$group": {

                    "_id": "$payment_type",

                    "total": {
                        "$sum": "$amount",
                    },

                    "count": {
                        "$sum": 1,
                    },

                }
            }

        ]

        return await db.payments.aggregate(
            pipeline
        ).to_list(None)

    # =====================================================
    # MATERIALS
    # =====================================================

    async def materials(
        self,
        company_id: str,
    ):

        return await db.materials.find(
            {
                "company_id": company_id,
            },
            {
                "_id": 0,
            },
        ).to_list(5000)

    async def low_stock_materials(
        self,
        company_id: str,
    ):

        return await db.materials.find(
            {
                "company_id": company_id,

                "$expr": {
                    "$lte": [
                        "$quantity",
                        "$minimum_quantity",
                    ]
                }

            },
            {
                "_id": 0,
            },
        ).to_list(200)

    # =====================================================
    # ATTENDANCE
    # =====================================================

    async def attendance(
        self,
        company_id: str,
    ):

        last_month = datetime.utcnow() - timedelta(days=30)

        pipeline = [

            {
                "$match": {

                    "company_id": company_id,

                    "date": {
                        "$gte": last_month.strftime("%Y-%m-%d"),
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
                                        "PRESENT",
                                    ]
                                },

                                1,

                                0,

                            ]

                        }

                    },

                    "absent": {

                        "$sum": {

                            "$cond": [

                                {
                                    "$eq": [
                                        "$status",
                                        "ABSENT",
                                    ]
                                },

                                1,

                                0,

                            ]

                        }

                    }

                }

            },

            {
                "$sort": {
                    "_id": 1,
                }
            }

        ]

        return await db.attendance.aggregate(
            pipeline
        ).to_list(31)

    async def attendance_today(
        self,
        company_id: str,
    ):

        today = datetime.utcnow().strftime("%Y-%m-%d")

        return await db.attendance.find(
            {
                "company_id": company_id,
                "date": today,
            },
            {
                "_id": 0,
            },
        ).to_list(1000)
        
        
            # =====================================================
    # TASKS
    # =====================================================

    async def pending_tasks(
        self,
        company_id: str,
    ):

        return await db.site_tasks.count_documents(
            {
                "company_id": company_id,
                "completed": False,
            }
        )

    async def completed_tasks(
        self,
        company_id: str,
    ):

        return await db.site_tasks.count_documents(
            {
                "company_id": company_id,
                "completed": True,
            }
        )

    async def recent_tasks(
        self,
        company_id: str,
        limit: int = 20,
    ):

        return await (
            db.site_tasks.find(
                {
                    "company_id": company_id,
                },
                {
                    "_id": 0,
                },
            )
            .sort(
                "created_at",
                -1,
            )
            .limit(limit)
            .to_list(limit)
        )

    # =====================================================
    # ACTIVITIES
    # =====================================================

    async def recent_payments(
        self,
        company_id: str,
        limit: int = 20,
    ):

        return await (
            db.payments.find(
                {
                    "company_id": company_id,
                },
                {
                    "_id": 0,
                },
            )
            .sort(
                "created_at",
                -1,
            )
            .limit(limit)
            .to_list(limit)
        )

    async def recent_reports(
        self,
        company_id: str,
        limit: int = 20,
    ):

        return await (
            db.daily_reports.find(
                {
                    "company_id": company_id,
                },
                {
                    "_id": 0,
                },
            )
            .sort(
                "created_at",
                -1,
            )
            .limit(limit)
            .to_list(limit)
        )

    # =====================================================
    # REUSABLE HELPERS
    # =====================================================

    async def site_progress(
        self,
        company_id: str,
    ):

        return await (
            db.sites.find(
                {
                    "company_id": company_id,
                },
                {
                    "_id": 0,
                    "name": 1,
                    "progress": 1,
                    "status": 1,
                },
            ).to_list(1000)
        )

    async def payment_breakdown(
        self,
        company_id: str,
    ):

        pipeline = [

            {
                "$match": {
                    "company_id": company_id,
                }
            },

            {
                "$group": {

                    "_id": "$payment_type",

                    "amount": {
                        "$sum": "$amount",
                    },

                }

            }

        ]

        return await db.payments.aggregate(
            pipeline
        ).to_list(None)

    async def material_breakdown(
        self,
        company_id: str,
    ):

        pipeline = [

            {
                "$match": {
                    "company_id": company_id,
                }
            },

            {
                "$group": {

                    "_id": "$category",

                    "amount": {
                        "$sum": "$total_cost",
                    },

                }

            }

        ]

        return await db.materials.aggregate(
            pipeline
        ).to_list(None)


dashboard_repository = DashboardRepository()