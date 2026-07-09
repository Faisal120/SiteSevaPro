import uuid

from datetime import datetime
from fastapi import HTTPException

from core import db

class ApplicationRepository:

    async def create(
        self,
        payload,
    ):

        document = {

            "id": str(uuid.uuid4()),

            "company_name": payload.company_name,

            "owner_name": payload.owner_name,

            "mobile": payload.mobile,

            "email": payload.email,

            "office_address": payload.office_address,

            "city": payload.city,

            "state": payload.state,

            "gst_number": payload.gst_number,

            "active_projects": payload.active_projects,

            "employee_count": payload.employee_count,

            "status": "PENDING",

            "remarks": None,

            "reviewed_by": None,

            "reviewed_at": None,

            "submitted_ip": None,

            "device": None,

            "attachments": [],

            "created_at": datetime.utcnow().isoformat(),

            "updated_at": datetime.utcnow().isoformat(),

        }

        db_document = document.copy()

        await db.applications.insert_one(
            db_document
        )

        return document

    async def get(
        self,
        application_id,
    ):

        return await db.applications.find_one(
            {
                "id": application_id
            },
            {
                "_id": 0
            },
        )

    async def list_pending(self):

        return await db.applications.find(
            {
                "status": "PENDING"
            },
            {
                "_id": 0
            },
        ).to_list(500)

    async def approve(
    self,
    application_id: str,
):

        await db.applications.update_one(

            {
                "id": application_id
            },

            {
                "$set": {

                    "status": "APPROVED",

                    "reviewed_at": datetime.utcnow().isoformat(),

                }
            },

        )

    async def reject(
        self,
        application_id,
    ):

        await db.applications.update_one(
            {
                "id": application_id
            },
            {
                "$set": {
                    "status": "REJECTED",
                    "reviewed_at": datetime.utcnow().isoformat(),
                }
            },
        )


# -----------------------------------------

    async def get_by_email(
        self,
        email: str,
    ):

        return await db.applications.find_one(
            {
                "email": email.lower()
            },
            {
                "_id": 0
            },
        )
        
    
    

application_repository = ApplicationRepository()