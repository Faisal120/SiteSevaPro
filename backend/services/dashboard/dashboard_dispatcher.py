from services.dashboard.contractor_dashboard_service import contractor_dashboard_service
from services.dashboard.supervisor_dashboard_service import supervisor_dashboard_service
from services.dashboard.client_dashboard_service import client_dashboard_service
from services.dashboard.admin_dashboard_service import admin_dashboard_service


class DashboardDispatcher:

    def _service(self, role: str):

        role = role.upper()

        if role in ("CONTRACTOR", "OWNER"):
            return contractor_dashboard_service

        if role == "SUPERVISOR":
            return supervisor_dashboard_service

        if role == "CLIENT":
            return client_dashboard_service

        if role == "SUPER_ADMIN":
            return admin_dashboard_service

        raise Exception(f"Unknown role: {role}")

    async def dashboard(self, user):

        service = self._service(user["role"])

        return await service.dashboard(user)

    async def bootstrap(self, user):

        service = self._service(user["role"])

        if hasattr(service, "bootstrap"):
            return await service.bootstrap(user)

        return {
            "role": user["role"],
            "permissions": [],
            "menu": [],
            "company": {},
        }


dashboard_dispatcher = DashboardDispatcher()