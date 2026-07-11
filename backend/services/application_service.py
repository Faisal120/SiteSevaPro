from fastapi import HTTPException

from repositories.audit_repository import audit_repository
from repositories.application_repository import application_repository
from services.provisioning_service import provisioning_service

import secrets

import string

import uuid

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
):

        application = await application_repository.get(
            application_id
        )

        if application is None:

            raise HTTPException(
                status_code=404,
                detail="Application not found",
            )

        result = await provisioning_service.provision(
            application
        )

        await application_repository.approve(
            application_id
        )

        await audit_repository.log(

            action="APPLICATION_APPROVED",

            description=f"{application['company_name']} approved.",

        )

        return {

            "success": True,

            "company": result["company"]["name"],

            "username": result["username"],

            "temporary_password": result["temporary_password"],

        }
        

    async def reject(
        self,
        application_id: str,
    ):
        return await application_repository.reject(
            application_id
        )

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