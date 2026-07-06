import asyncio
from datetime import datetime

from repositories.dashboard_repository import dashboard_repository


class DashboardService:

    async def get_dashboard(self, user):

        company_id = user["company_id"]

        (
            sites,
            team,
            reports,
            payments,
            materials,
            attendance,
            company,
            total_sites,
            active_sites,
            completed_sites,
            total_labours,
            today_labours,
            pending_tasks,
            completed_tasks,
            today_reports,
        ) = await asyncio.gather(

            dashboard_repository.get_sites(company_id),

            dashboard_repository.get_team(company_id),

            dashboard_repository.latest_reports(company_id),

            dashboard_repository.payments(company_id),

            dashboard_repository.materials(company_id),

            dashboard_repository.attendance(company_id),

            dashboard_repository.company(company_id),

            dashboard_repository.total_sites(company_id),

            dashboard_repository.active_sites(company_id),

            dashboard_repository.completed_sites(company_id),

            dashboard_repository.total_labours(company_id),

            dashboard_repository.todays_labours(company_id),

            dashboard_repository.pending_tasks(company_id),

            dashboard_repository.completed_tasks(company_id),

            dashboard_repository.todays_reports(company_id),

        )

        stats = self.build_stats(
            sites,
            payments,
            materials,
            attendance,
            total_sites,
            active_sites,
            completed_sites,
            total_labours,
            today_labours,
            pending_tasks,
            completed_tasks,
            today_reports,
        )

        charts = self.build_charts(
            sites,
            materials,
            payments,
            attendance,
        )

        latest_photos = self.extract_latest_photos(
            reports
        )

        alerts = self.generate_alerts(
            stats,
            materials,
            attendance,
        )

        activities = self.build_recent_activities(
            payments,
            reports,
            attendance,
        )

        return {

            "company": company,

            "stats": stats,

            "sites": sites,

            "team": team,

            "latestPhotos": latest_photos,

            "alerts": alerts,

            "activities": activities,

            "charts": charts,

        }
        
    def build_stats(

        self,

        sites,

        payments,

        materials,

        attendance,

        total_sites,

        active_sites,

        completed_sites,

        total_labours,

        today_labours,

        pending_tasks,

        completed_tasks,

        today_reports,

    ):

        total_budget = sum(
            s.get("budget", 0)
            for s in sites
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
                "payment_type"
            )

            status = payment.get(
                "status"
            )

            if payment_type == "CLIENT_RECEIVED":

                income += amount

            else:

                expense += amount

            if status == "PENDING":

                pending_payment += amount

        net_profit = income - expense

        productivity = 0

        if total_sites:

            productivity = round(
                (
                    completed_sites
                    /
                    total_sites
                ) * 100,
                1,
            )

        return {

            "total_sites": total_sites,

            "active_sites": active_sites,

            "completed_sites": completed_sites,

            "labours": total_labours,

            "today_labours": today_labours,

            "pending_tasks": pending_tasks,

            "completed_tasks": completed_tasks,

            "today_reports": today_reports,

            "cashflow": income,

            "pending_payments": pending_payment,

            "total_budget": total_budget,

            "net_profit": net_profit,

            "productivity": productivity,

        }
        
    def build_charts(

        self,

        sites,

        materials,

        payments,

        attendance,

    ):

        site_progress = []

        expense_breakdown = {}

        attendance_chart = []

        monthly_cashflow = {}

        for site in sites:

            site_progress.append({

                "name": site.get("name"),

                "progress": site.get(

                    "progress",

                    0,

                )

            })

        for material in materials:

            category = material.get(

                "category",

                "Others"

            )

            expense_breakdown.setdefault(

                category,

                0,

            )

            expense_breakdown[category] += material.get(

                "total_cost",

                material.get(

                    "amount",

                    0,

                )

            )

        for payment in payments:

            created = payment.get(

                "created_at"

            )

            if created:

                month = created.strftime("%b")

            else:

                month = "Unknown"

            monthly_cashflow.setdefault(

                month,

                {

                    "income": 0,

                    "expense": 0,

                }

            )

            amount = payment.get(

                "amount",

                0,

            )

            if payment.get(

                "payment_type"

            ) == "CLIENT_RECEIVED":

                monthly_cashflow[month]["income"] += amount

            else:

                monthly_cashflow[month]["expense"] += amount

        for item in attendance:

            attendance_chart.append({

                "date": item.get("date"),

                "present": item.get(

                    "present",

                    0,

                ),

                "absent": item.get(

                    "absent",

                    0,

                )

            })

        return {

            "site_progress": site_progress,

            "expense_breakdown": [

                {

                    "name": k,

                    "value": v,

                }

                for k, v in expense_breakdown.items()

            ],

            "attendance": attendance_chart,

            "cashflow": [

                {

                    "month": month,

                    **value,

                }

                for month, value in monthly_cashflow.items()

            ]

        }
        
    def extract_latest_photos(

        self,

        reports,

    ):

        photos = []

        for report in reports:

            media = report.get(

                "media_urls",

                []

            )

            for file in media:

                if file.get("type") == "image":

                    photos.append({

                        "url": file.get("url"),

                        "site_id": report.get("site_id"),

                        "site_name": report.get("site_name"),

                        "report_date": report.get("date"),

                    })

        photos.sort(

            key=lambda x: x["report_date"],

            reverse=True,

        )

        return photos[:8]
    
    
    def generate_alerts(

        self,

        stats,

        materials,

        attendance,

    ):

        alerts = []

        if stats["pending_tasks"]:

            alerts.append({

                "type": "task",

                "title": f"{stats['pending_tasks']} Pending Tasks",

                "severity": "high",

            })

        if stats["pending_payments"]:

            alerts.append({

                "type": "payment",

                "title": "Pending Client Payments",

                "severity": "medium",

            })

        low_stock = 0

        for item in materials:

            if item.get(

                "quantity",

                0,

            ) <= item.get(

                "minimum_quantity",

                0,

            ):

                low_stock += 1

        if low_stock:

            alerts.append({

                "type": "material",

                "title": f"{low_stock} Materials Running Low",

                "severity": "high",

            })

        absent = 0

        present = 0

        for item in attendance:

            absent += item.get(

                "absent",

                0,

            )

            present += item.get(

                "present",

                0,

            )

        if present and absent:

            ratio = absent / (present + absent)

            if ratio > 0.25:

                alerts.append({

                    "type": "attendance",

                    "title": "High Labour Absenteeism",

                    "severity": "medium",

                })

        return alerts
    
    
    def build_recent_activities(

        self,

        payments,

        reports,

        attendance,

    ):

        activities = []

        for payment in payments:

            activities.append({

                "id": str(payment["_id"]),

                "type": "PAYMENT",

                "title": payment.get(

                    "payment_type",

                    "Payment",

                ),

                "body": f"₹ {payment.get('amount',0):,.0f}",

                "created_at": payment.get(

                    "created_at"

                )

            })

        for report in reports:

            activities.append({

                "id": str(report["_id"]),

                "type": "SITE",

                "title": report.get(

                    "site_name",

                    "Daily Report",

                ),

                "body": report.get(

                    "description",

                    "",

                ),

                "created_at": report.get(

                    "created_at"

                )

            })

        activities.sort(

            key=lambda x: x.get(

                "created_at"

            ) or datetime.min,

            reverse=True,

        )

        return activities[:20]
    
    
    