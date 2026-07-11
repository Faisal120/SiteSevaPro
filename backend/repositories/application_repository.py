from fastapi import HTTPException

from repositories.application_repository import application_repository

from repositories.audit_repository import audit_repository

from services.provisioning_service import provisioning_service


class ApplicationService:

    # =====================================================
    # Submit Application
    # =====================================================

    async def submit_application(
        self,
        payload,
    ):

        existing = await application_repository.get_by_email(
            payload.email.lower()
        )

        if existing:

            if existing["status"] == "PENDING":

                raise HTTPException(
                    status_code=409,
                    detail="Application already submitted.",
                )

            if existing["status"] == "APPROVED":

                raise HTTPException(
                    status_code=409,
                    detail="Company already exists.",
                )

        payload.company_name = payload.company_name.strip()

        payload.owner_name = payload.owner_name.strip()

        payload.email = payload.email.lower().strip()

        payload.city = payload.city.strip()

        payload.state = payload.state.strip()

        application = await application_repository.create(
            payload
        )

        try:

            await audit_repository.log(

                action="APPLICATION_SUBMITTED",

                description=f"{payload.company_name} submitted contractor application."

            )

        except Exception:

            pass

        return application

    # =====================================================
    # Get Application
    # =====================================================

    async def get(
        self,
        application_id: str,
    ):

        application = await application_repository.get(
            application_id
        )

        if application is None:

            raise HTTPException(

                status_code=404,

                detail="Application not found.",

            )

        return application

    # =====================================================
    # List Pending
    # =====================================================

    async def list_pending(self):

        return await application_repository.list_pending()

    # =====================================================
    # Approve Application
    # =====================================================

    async def approve(
        self,
        application_id: str,
    ):

        application = await self.get(
            application_id
        )

        result = await provisioning_service.provision_company(
            application
        )

        await application_repository.approve(
            application_id
        )

        return {

            "success": True,

            "company": result["company"]["name"],

            "username": result["username"],

            "temporary_password": result["temporary_password"],

        }

    # =====================================================
    # Reject Application
    # =====================================================

    async def reject(
        self,
        application_id: str,
    ):

        application = await self.get(
            application_id
        )

        if application["status"] == "REJECTED":

            raise HTTPException(

                status_code=400,

                detail="Application already rejected.",

            )

        await application_repository.reject(
            application_id
        )

        return {

            "success": True,

            "message": "Application rejected."

        }


application_service = ApplicationService()