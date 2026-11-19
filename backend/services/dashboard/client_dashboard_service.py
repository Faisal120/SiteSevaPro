"""
Client Dashboard

Read Only Dashboard

Production Ready
"""

import asyncio

from repositories.dashboard_repository import (
    dashboard_repository,
)

from services.dashboard.builders.stats_builder import (
    StatsBuilder,
)

from services.dashboard.builders.photos_builder import PhotosBuilder
from services.dashboard.builders.activities_builder import ActivitiesBuilder
from services.dashboard.builders.alerts_builder import AlertsBuilder


class ClientDashboardService:

    # =====================================================
    # DASHBOARD
    # =====================================================

    async def dashboard(
        self,
        user,
    ):

        dashboard = await self._load_dashboard(
            user,
        )

        stats = StatsBuilder.build(
            dashboard,
        )

        return {

            "company": dashboard["company"],

            "stats": stats,

            "sites": dashboard["sites"],

            "latestPhotos": PhotosBuilder.build(
                dashboard["reports"],
            ),

            "activities": ActivitiesBuilder.contractor(
                dashboard,
            ),

            "alerts": AlertsBuilder.contractor(
                stats,
                dashboard,
            ),

            "payments": dashboard["payments"],

        }

    # =====================================================
    # LOAD
    # =====================================================

    async def _load_dashboard(
        self,
        user,
    ):

        company_id = user["company_id"]

        user_id = user["id"]

        (

            company,

            assigned_sites,

            reports,

            total_sites,

            active_sites,

            completed_sites,

        ) = await asyncio.gather(

            dashboard_repository.company(
                company_id,
            ),

            dashboard_repository.get_sites(
                company_id,
                "CLIENT",
                user_id,
                user.get("email"),
                user.get("site_ids", []),
            ),

            dashboard_repository.latest_reports(
                company_id,
            ),

            dashboard_repository.total_sites(
                company_id,
                "CLIENT",
                user_id,
                user.get("email"),
                user.get("site_ids", []),
            ),

            dashboard_repository.active_sites(
                company_id,
                "CLIENT",
                user_id,
                user.get("email"),
                user.get("site_ids", []),
            ),

            dashboard_repository.completed_sites(
                company_id,
                "CLIENT",
                user_id,
                user.get("email"),
                user.get("site_ids", []),
            ),

        )

        # Payment scope depends on the resolved client project IDs, so it must
        # run after the independent dashboard queries above have completed.
        payments = await dashboard_repository.payments(
            company_id,
            20,
            [site["id"] for site in assigned_sites],
        )

        return {

            "company": company,

            "sites": assigned_sites,

            "reports": reports,

            "payments": [
                payment
                for payment in payments
                if str(
                    payment.get("type") or payment.get("payment_type") or ""
                ).upper() == "CLIENT_RECEIVED"
            ],

            "team": [],

            "materials": [],

            "attendance": [],

            "total_sites": total_sites,

            "active_sites": active_sites,

            "completed_sites": completed_sites,

            "total_labours": 0,

            "todays_labours": 0,

            "pending_tasks": 0,

            "completed_tasks": 0,

            "todays_reports": 0,

        }


client_dashboard_service = ClientDashboardService() 
