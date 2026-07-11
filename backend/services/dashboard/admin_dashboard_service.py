"""
Admin Dashboard Service

Platform Dashboard

Production Ready
"""

import asyncio

from repositories.admin_repository import admin_repository


class AdminDashboardService:

    async def dashboard(
        self,
        user: dict,
    ):

        (
            total_companies,
            active_companies,
            total_users,
            total_sites,
            active_subscriptions,
            revenue,
            analytics,
            audit_logs,
            contractors,
            subscriptions,
        ) = await asyncio.gather(

            admin_repository.total_companies(),

            admin_repository.active_companies(),

            admin_repository.total_users(),

            admin_repository.total_sites(),

            admin_repository.active_subscriptions(),

            admin_repository.subscription_revenue(),

            admin_repository.platform_analytics(),

            admin_repository.audit_logs(),

            admin_repository.contractors(
                0,
                10,
            ),

            admin_repository.subscriptions(
                0,
                10,
            ),

        )

        stats = {

            "total_companies": total_companies,

            "active_companies": active_companies,

            "total_users": total_users,

            "total_sites": total_sites,

            "active_subscriptions": active_subscriptions,

            "subscription_revenue": revenue,

        }

        alerts = []

        if active_subscriptions < total_companies:

            alerts.append({

                "type": "SUBSCRIPTION",

                "severity": "MEDIUM",

                "title": "Some companies have inactive subscriptions",

            })

        if total_companies == 0:

            alerts.append({

                "type": "SYSTEM",

                "severity": "LOW",

                "title": "No companies registered",

            })

        activities = []

        for log in audit_logs:

            activities.append({

                "id": log.get("id"),

                "type": log.get("action"),

                "title": log.get("description"),

                "created_at": log.get("created_at"),

            })

        return {

            "company": {

                "name": "SiteSeva Pro",

                "role": "SUPER_ADMIN",

            },

            "stats": stats,

            "analytics": analytics,

            "alerts": alerts,

            "activities": activities[:20],

            "contractors": contractors,

            "subscriptions": subscriptions,

        }


admin_dashboard_service = AdminDashboardService()