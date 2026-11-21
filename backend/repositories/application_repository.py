import uuid
from datetime import datetime

from core import db
from pymongo import ReturnDocument


class ApplicationRepository:

    # =====================================================
    # CREATE
    # =====================================================

    async def create(
        self,
        payload,
    ):

        document = {

            "id": str(uuid.uuid4()),

            "company_name": payload.company_name,

            "owner_name": payload.owner_name,

            "mobile": payload.mobile,

            "email": payload.email.lower(),

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

        await db.applications.insert_one(document)

        return document

    # =====================================================
    # GET
    # =====================================================

    async def get(
        self,
        application_id: str,
    ):

        return await db.applications.find_one(

            {
                "id": application_id,
            },

            {
                "_id": 0,
            },

        )

    # =====================================================
    # GET BY EMAIL
    # =====================================================

    async def get_by_email(
        self,
        email: str,
    ):

        return await db.applications.find_one(

            {
                "email": email.lower(),
            },

            {
                "_id": 0,
            },

        )

    # =====================================================
    # LIST PENDING
    # =====================================================

    async def list_pending(
        self,
        limit: int = 500,
    ):

        return await (

            db.applications

            .find(

                {
                    "status": "PENDING",
                },

                {
                    "_id": 0,
                },

            )

            .sort(

                "created_at",

                -1,

            )

            .limit(limit)

            .to_list(limit)

        )

    # =====================================================
    # APPROVE
    # =====================================================

    async def approve(
        self,
        application_id: str,
        reviewed_by: str | None = None,
    ):

        await db.applications.update_one(

            {
                "id": application_id,
            },

            {
                "$set": {

                    "status": "APPROVED",

                    "reviewed_by": reviewed_by,

                    "reviewed_at": datetime.utcnow().isoformat(),

                    "updated_at": datetime.utcnow().isoformat(),

                }

            },

        )

    async def claim_for_approval(
        self,
        application_id: str,
        reviewed_by: str | None = None,
    ):
        return await db.applications.find_one_and_update(
            {"id": application_id, "status": "PENDING"},
            {
                "$set": {
                    "status": "PROCESSING",
                    "reviewed_by": reviewed_by,
                    "updated_at": datetime.utcnow().isoformat(),
                }
            },
            projection={"_id": 0},
            return_document=ReturnDocument.AFTER,
        )

    async def release_approval(self, application_id: str, reason: str):
        await db.applications.update_one(
            {"id": application_id, "status": "PROCESSING"},
            {
                "$set": {
                    "status": "PENDING",
                    "provisioning_error": reason[:500],
                    "updated_at": datetime.utcnow().isoformat(),
                }
            },
        )

    async def complete_approval(
        self,
        application_id: str,
        *,
        reviewed_by: str | None,
        user_id: str,
        company_id: str,
        delivery_status: str,
    ):
        await db.applications.update_one(
            {"id": application_id, "status": "PROCESSING"},
            {
                "$set": {
                    "status": "APPROVED",
                    "reviewed_by": reviewed_by,
                    "reviewed_at": datetime.utcnow().isoformat(),
                    "approved_at": datetime.utcnow().isoformat(),
                    "user_id": user_id,
                    "company_id": company_id,
                    "credential_delivery_status": delivery_status,
                    "updated_at": datetime.utcnow().isoformat(),
                },
                "$unset": {"provisioning_error": ""},
            },
        )

    # =====================================================
    # REJECT
    # =====================================================

    async def reject(
        self,
        application_id: str,
        reviewed_by: str | None = None,
        remarks: str | None = None,
    ):

        await db.applications.update_one(

            {
                "id": application_id,
            },

            {
                "$set": {

                    "status": "REJECTED",

                    "reviewed_by": reviewed_by,

                    "remarks": remarks,

                    "reviewed_at": datetime.utcnow().isoformat(),

                    "updated_at": datetime.utcnow().isoformat(),

                }

            },

        )


application_repository = ApplicationRepository()
