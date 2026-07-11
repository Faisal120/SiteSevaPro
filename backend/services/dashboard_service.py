from repositories.dashboard_repository import (
    dashboard_repository,
)

from services.dashboard.dashboard_dispatcher import (
    dashboard_dispatcher,
)


class DashboardService:

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

    async def dashboard(
        self,
        user,
    ):

        return await dashboard_dispatcher.get_dashboard(
            user
        )


dashboard_service = DashboardService()