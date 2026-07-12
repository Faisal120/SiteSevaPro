"""
Contractor Dashboard Service

Responsible only for Contractor/Owner Dashboard.

Production Ready
"""

import asyncio

from repositories.dashboard_repository import (
    dashboard_repository,
)

from services.dashboard.builders.stats_builder import (
    StatsBuilder,
)

from services.dashboard.builders.charts_builders import ChartsBuilder
from services.dashboard.builders.photos_builder import PhotosBuilder
from services.dashboard.builders.activities_builder import ActivitiesBuilder
from services.dashboard.builders.alerts_builder import AlertsBuilder

class ContractorDashboardService:

    # =====================================================
    # DASHBOARD
    # =====================================================

    async def dashboard(
        self,
        user,
    ):

        dashboard = await self._load_dashboard_data(
            user
        )

        stats = StatsBuilder.build(
            dashboard
        )

        return {

            "company": dashboard["company"],

            "stats": stats,

            "sites": dashboard["sites"],

            "team": dashboard["team"],

            "charts": ChartsBuilder.build(dashboard),

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

        }

    # =====================================================
    # LOAD
    # =====================================================

    async def _load_dashboard_data(
        self,
        user,
    ):

        company_id = user["company_id"]

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
            ),

            dashboard_repository.active_sites(
                company_id,
            ),

            dashboard_repository.completed_sites(
                company_id,
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


contractor_dashboard_service = ContractorDashboardService()