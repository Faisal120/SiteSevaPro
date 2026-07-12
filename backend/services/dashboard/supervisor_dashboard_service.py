"""
Supervisor Dashboard

Only Assigned Sites
No Company Analytics
No Financial Data

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


class SupervisorDashboardService:

    # ==========================================================
    # DASHBOARD
    # ==========================================================

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

            "todayAttendance": dashboard["attendance"],

            "reports": dashboard["reports"],

            "activities": ActivitiesBuilder.contractor(
                dashboard,
            ),

            "alerts": AlertsBuilder.contractor(
                stats,
                dashboard,
            ),

        }

    # ==========================================================
    # LOAD
    # ==========================================================

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

            attendance,

            total_sites,

            active_sites,

            completed_sites,

            pending_tasks,

            completed_tasks,

            todays_reports,

        ) = await asyncio.gather(

            dashboard_repository.company(
                company_id,
            ),

            dashboard_repository.get_sites(
                company_id,
                "SUPERVISOR",
                user_id,
            ),

            dashboard_repository.latest_reports(
                company_id,
            ),

            dashboard_repository.attendance_today(
                company_id,
            ),

            dashboard_repository.total_sites(
                company_id,
                "SUPERVISOR",
                user_id,
            ),

            dashboard_repository.active_sites(
                company_id,
                "SUPERVISOR",
                user_id,
            ),

            dashboard_repository.completed_sites(
                company_id,
                "SUPERVISOR",
                user_id,
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

            "sites": assigned_sites,

            "team": [],

            "payments": [],

            "materials": [],

            "attendance": attendance,

            "reports": reports,

            "total_sites": total_sites,

            "active_sites": active_sites,

            "completed_sites": completed_sites,

            "total_labours": 0,

            "todays_labours": 0,

            "pending_tasks": pending_tasks,

            "completed_tasks": completed_tasks,

            "todays_reports": todays_reports,

        }

supervisor_dashboard_service = SupervisorDashboardService()