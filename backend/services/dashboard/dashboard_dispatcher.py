from services.dashboard.contractor_dashboard_service import (
    contractor_dashboard_service,
)

from services.dashboard.supervisor_dashboard_service import (
    supervisor_dashboard_service,
)

from services.dashboard.client_dashboard_service import (
    client_dashboard_service,
)

from services.dashboard.admin_dashboard_service import (
    admin_dashboard_service,
)


class DashboardDispatcher:

    async def get_dashboard(
        self,
        user: dict,
    ):

        role = user.get(
            "role",
            "",
        ).upper()

        dispatch = {

            "CONTRACTOR": contractor_dashboard_service,

            "OWNER": contractor_dashboard_service,

            "SUPERVISOR": supervisor_dashboard_service,

            "CLIENT": client_dashboard_service,

            "SUPER_ADMIN": admin_dashboard_service,

        }

        service = dispatch.get(role)

        if service is None:

            raise Exception(
                f"Unsupported dashboard role: {role}"
            )

        return await service.dashboard(
            user
        )


dashboard_dispatcher = DashboardDispatcher()