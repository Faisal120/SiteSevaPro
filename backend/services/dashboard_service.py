import asyncio
from repositories.dashboard_repository import (
    dashboard_repository,
)


class DashboardService:

    # =====================================================
    # BOOTSTRAP
    # =====================================================

    async def bootstrap(
        self,
        user,
    ):

        company = await dashboard_repository.company(
            user["company_id"]
        )

        return {

            "company": company,

            "user": {

                "id": user["id"],

                "name": user.get("full_name"),

                "email": user.get("email"),

                "role": user.get("role"),

            },

            "permissions": {

                "role": user.get("role"),

            },

        }

    # =====================================================
    # CONTRACTOR DASHBOARD
    # =====================================================

    async def contractor_dashboard(
        self,
        user,
    ):

        return await self.get_dashboard(
            user
        )

    # =====================================================
    # MAIN DASHBOARD
    # =====================================================

    async def get_dashboard(
        self,
        user,
    ):

        dashboard = await self._load_dashboard_data(
            user
        )
       
        print("=" * 80)
        print("DASHBOARD DATA")
        print(dashboard)
        print("=" * 80)

        stats = self._build_stats(
            dashboard
        )
        
        print("=" * 80)
        print("STATS")
        print(stats)
        print("=" * 80)

        charts = self._build_charts(
            dashboard
        )

        latest_photos = self._build_latest_photos(
            dashboard["reports"]
        )

        alerts = self._build_alerts(
            dashboard,
            stats,
        )

        activities = self._build_recent_activities(
            dashboard,
        )

        return {

            "company": dashboard["company"],

            "stats": stats,

            "sites": dashboard["sites"],

            "team": dashboard["team"],

            "latestPhotos": latest_photos,

            "alerts": alerts,

            "activities": activities,

            "charts": charts,

        }

    # =====================================================
    # LOAD DASHBOARD DATA
    # =====================================================

    async def _load_dashboard_data(
        self,
        user,
    ):

        role = user.get("role", "CONTRACTOR")

        company_id = user["company_id"]

        user_id = user["id"]

        (
            company,

            sites,

            team,

            reports,

            payments,

            materials,

            attendance,

            total_sites,

            active_sites,

            completed_sites,

            total_labours,

            todays_labours,

            pending_tasks,

            completed_tasks,

            todays_reports,

        ) = await asyncio.gather(

            dashboard_repository.company(
                company_id,
            ),

            dashboard_repository.get_sites(
                company_id,
                role,
                user_id,
            ),

            dashboard_repository.get_team(
                company_id,
            ),

            dashboard_repository.latest_reports(
                company_id,
            ),

            dashboard_repository.payments(
                company_id,
            ),

            dashboard_repository.materials(
                company_id,
            ),

            dashboard_repository.attendance(
                company_id,
            ),

            dashboard_repository.total_sites(
                company_id,
                role,
                user_id,
            ),

            dashboard_repository.active_sites(
                company_id,
                role,
                user_id,
            ),

            dashboard_repository.completed_sites(
                company_id,
                role,
                user_id,
            ),

            dashboard_repository.total_labours(
                company_id,
            ),

            dashboard_repository.todays_labours(
                company_id,
            ),

            dashboard_repository.pending_tasks(
                company_id,
            ),

            dashboard_repository.completed_tasks(
                company_id,
            ),

            dashboard_repository.todays_reports(
                company_id,
            ),

        )

        return {

            "company": company,

            "sites": sites,

            "team": team,

            "reports": reports,

            "payments": payments,

            "materials": materials,

            "attendance": attendance,

            "total_sites": total_sites,

            "active_sites": active_sites,

            "completed_sites": completed_sites,

            "total_labours": total_labours,

            "todays_labours": todays_labours,

            "pending_tasks": pending_tasks,

            "completed_tasks": completed_tasks,

            "todays_reports": todays_reports,

        }
        
        
            # =====================================================
    # BUILD STATS
    # =====================================================

    def _build_stats(
        self,
        data: dict,
    ):

        sites = data["sites"]
        payments = data["payments"]
        materials = data["materials"]

        total_budget = sum(
            site.get("budget", 0)
            for site in sites
        )

        income = 0
        expense = 0
        pending_payment = 0

        for payment in payments:

            amount = payment.get(
                "amount",
                0,
            )

            payment_type = payment.get(
                "payment_type",
            )

            status = payment.get(
                "status",
            )

            if payment_type == "CLIENT_RECEIVED":

                income += amount

            else:

                expense += amount

            if status == "PENDING":

                pending_payment += amount

        net_profit = income - expense

        productivity = 0

        if data["total_sites"]:

            productivity = round(

                (
                    data["completed_sites"]
                    /
                    data["total_sites"]
                ) * 100,

                1,

            )

        low_stock = 0

        for material in materials:

            if material.get(
                "quantity",
                0,
            ) <= material.get(
                "minimum_quantity",
                0,
            ):

                low_stock += 1

        return {

            "total_sites": data["total_sites"],

            "active_sites": data["active_sites"],

            "completed_sites": data["completed_sites"],

            "labours": data["total_labours"],

            "today_labours": data["todays_labours"],

            "pending_tasks": data["pending_tasks"],

            "completed_tasks": data["completed_tasks"],

            "today_reports": data["todays_reports"],

            "cashflow": income,

            "expense": expense,

            "pending_payments": pending_payment,

            "net_profit": net_profit,

            "total_budget": total_budget,

            "low_stock": low_stock,

            "productivity": productivity,

        }

    # =====================================================
    # BUILD CHARTS
    # =====================================================

    def _build_charts(
        self,
        data: dict,
    ):

        site_progress = []

        expense_breakdown = {}

        attendance_chart = []

        cashflow = {}

        # ---------------------------------------------
        # Site Progress
        # ---------------------------------------------

        for site in data["sites"]:

            site_progress.append(

                {

                    "name": site.get(
                        "name"
                    ),

                    "progress": site.get(
                        "progress",
                        0,
                    ),

                }

            )

        # ---------------------------------------------
        # Material Breakdown
        # ---------------------------------------------

        for material in data["materials"]:

            category = material.get(
                "category",
                "Others",
            )

            expense_breakdown.setdefault(
                category,
                0,
            )

            expense_breakdown[
                category
            ] += material.get(
                "total_cost",
                material.get(
                    "amount",
                    0,
                ),
            )

        # ---------------------------------------------
        # Monthly Cashflow
        # ---------------------------------------------

        for payment in data["payments"]:

            created = payment.get(
                "created_at"
            )

            if not created:

                continue

            if hasattr(
                created,
                "strftime",
            ):

                month = created.strftime(
                    "%b"
                )

            else:

                month = str(created)[:7]

            cashflow.setdefault(

                month,

                {

                    "income": 0,

                    "expense": 0,

                },

            )

            amount = payment.get(
                "amount",
                0,
            )

            if payment.get(
                "payment_type"
            ) == "CLIENT_RECEIVED":

                cashflow[
                    month
                ]["income"] += amount

            else:

                cashflow[
                    month
                ]["expense"] += amount

        # ---------------------------------------------
        # Attendance
        # ---------------------------------------------

        for item in data["attendance"]:

            attendance_chart.append(

                {

                    "date": item.get(
                        "_id"
                    ),

                    "present": item.get(
                        "present",
                        0,
                    ),

                    "absent": item.get(
                        "absent",
                        0,
                    ),

                }

            )

        return {

            "site_progress": site_progress,

            "expense_breakdown": [

                {

                    "name": key,

                    "value": value,

                }

                for key, value in expense_breakdown.items()

            ],

            "attendance": attendance_chart,

            "cashflow": [

                {

                    "month": month,

                    **values,

                }

                for month, values in cashflow.items()

            ],

        }
        
            # =====================================================
    # BUILD LATEST PHOTOS
    # =====================================================

    def _build_latest_photos(
        self,
        reports,
    ):

        photos = []

        for report in reports:

            media = report.get(
                "media_urls",
                report.get(
                    "photos",
                    [],
                ),
            )

            for item in media:

                if item.get("type") != "image":
                    continue

                photos.append(

                    {

                        "url": item.get("url"),

                        "thumbnail": item.get(
                            "thumbnail",
                            item.get("url"),
                        ),

                        "caption": item.get(
                            "caption"
                        ),

                        "site_id": report.get(
                            "site_id"
                        ),

                        "site_name": report.get(
                            "site_name"
                        ),

                        "created_at": report.get(
                            "created_at"
                        ),

                    }

                )

        photos.sort(

            key=lambda x: x.get(
                "created_at"
            ),

            reverse=True,

        )

        return photos[:8]

    # =====================================================
    # BUILD RECENT ACTIVITIES
    # =====================================================

    def _build_recent_activities(
        self,
        data,
    ):

        activities = []

        # ---------------------------------------------
        # Payments
        # ---------------------------------------------

        for payment in data["payments"]:

            activities.append(

                {

                    "id": payment.get("id"),

                    "type": "PAYMENT",

                    "title": payment.get(
                        "payment_type",
                        "Payment",
                    ),

                    "description": f"₹ {payment.get('amount',0):,.0f}",

                    "created_at": payment.get(
                        "created_at"
                    ),

                }

            )

        # ---------------------------------------------
        # Reports
        # ---------------------------------------------

        for report in data["reports"]:

            activities.append(

                {

                    "id": report.get("id"),

                    "type": "REPORT",

                    "title": report.get(
                        "site_name",
                        "Daily Report",
                    ),

                    "description": report.get(
                        "description",
                        "",
                    ),

                    "created_at": report.get(
                        "created_at"
                    ),

                }

            )

        activities.sort(

            key=lambda x: x.get(
                "created_at"
            ),

            reverse=True,

        )

        return activities[:20]

    # =====================================================
    # BUILD ALERTS
    # =====================================================

    def _build_alerts(
        self,
        data,
        stats,
    ):

        alerts = []

        # Pending Tasks

        if stats["pending_tasks"]:

            alerts.append(

                {

                    "type": "TASK",

                    "severity": "HIGH",

                    "title": f"{stats['pending_tasks']} Pending Tasks",

                }

            )

        # Pending Payments

        if stats["pending_payments"]:

            alerts.append(

                {

                    "type": "PAYMENT",

                    "severity": "MEDIUM",

                    "title": "Pending Client Payments",

                }

            )

        # Low Stock

        if stats["low_stock"]:

            alerts.append(

                {

                    "type": "MATERIAL",

                    "severity": "HIGH",

                    "title": f"{stats['low_stock']} Materials Running Low",

                }

            )

        # No Sites

        if stats["total_sites"] == 0:

            alerts.append(

                {

                    "type": "SITE",

                    "severity": "LOW",

                    "title": "Create your first construction site.",

                }

            )

        # No Team

        if len(data["team"]) == 0:

            alerts.append(

                {

                    "type": "TEAM",

                    "severity": "LOW",

                    "title": "No Supervisors or Clients added.",

                }

            )

        return alerts


dashboard_service = DashboardService()