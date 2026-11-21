from fastapi import HTTPException

from repositories.audit_repository import audit_repository
from repositories.application_repository import application_repository
from services.provisioning_service import provisioning_service
from repositories.user_repository import user_repository
from services.outbound_notification_service import outbound_notification_service

class ApplicationService:


    async def submit_application(
        self,
        payload,
    ):

        existing = await application_repository.get_by_email(
            payload.email
        )

        if existing:

            if existing["status"] == "PENDING":

                raise HTTPException(
                    status_code=409,
                    detail="Your application is already under review.",
                )

            if existing["status"] == "APPROVED":

                raise HTTPException(
                    status_code=409,
                    detail="Company already approved.",
                )

        payload.company_name = payload.company_name.strip()

        payload.owner_name = payload.owner_name.strip()

        payload.email = payload.email.lower().strip()

        payload.city = payload.city.strip()

        payload.state = payload.state.strip()
        
        await audit_repository.log(
        
                action="APPLICATION_SUBMITTED",
        
                description=f"{payload.company_name} submitted contractor application."
        
            )

        return await application_repository.create(
            payload
        )
        
        
    async def approve(
        self,
        application_id: str,
        reviewed_by: str | None = None,
    ):
        application = await application_repository.claim_for_approval(
            application_id,
            reviewed_by,
        )
        if application is None:
            existing = await application_repository.get(application_id)
            if existing is None:
                raise HTTPException(404, "Application not found")
            raise HTTPException(409, f"Application is already {existing['status'].lower()}")

        if await user_repository.get_by_email(application["email"]):
            await application_repository.release_approval(
                application_id,
                "A user with this email already exists",
            )
            raise HTTPException(409, "A user with this email already exists")

        try:
            result = await provisioning_service.provision_company(application)
        except Exception as error:
            await application_repository.release_approval(application_id, str(error))
            raise HTTPException(500, "Company provisioning failed; no approval was recorded") from error

        delivery = await outbound_notification_service.send_credentials(
            result["contractor"],
            result["temporary_password"],
        )
        await user_repository.update(
            result["contractor"]["id"],
            {
                "credential_delivery_status": delivery.get("status"),
                "credential_delivery_id": delivery.get("id"),
            },
        )
        await application_repository.complete_approval(
            application_id,
            reviewed_by=reviewed_by,
            user_id=result["contractor"]["id"],
            company_id=result["company"]["id"],
            delivery_status=delivery.get("status", "UNKNOWN"),
        )

        await audit_repository.log(

            action="APPLICATION_APPROVED",

            description=f"{application['company_name']} approved.",

        )

        return {

            "success": True,

            "company": result["company"]["name"],

            "username": result["username"],

            "email": result["contractor"]["email"],

            "whatsapp_delivery": delivery,

        }
        

    async def reject(
        self,
        application_id: str,
        reviewed_by: str | None = None,
        remarks: str | None = None,
    ):
        application = await application_repository.get(application_id)
        if application is None:
            raise HTTPException(404, "Application not found")
        if application.get("status") != "PENDING":
            raise HTTPException(409, "Only pending applications can be rejected")
        await application_repository.reject(application_id, reviewed_by, remarks)
        return {"success": True}

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
                detail="Application not found",
            )

        return application

    async def list_pending(self):
        return await application_repository.list_pending()
    
    
    

application_service = ApplicationService()
