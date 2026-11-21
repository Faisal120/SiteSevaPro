from typing import Optional

from core import db

import uuid
from datetime import datetime

from services.account_security import normalize_phone


class UserRepository:

    # -----------------------------------------

    async def get_by_email(
        self,
        email: str,
    ) -> Optional[dict]:

        return await db.users.find_one(
            {
                "email": email.lower()
            },
            {
                "_id": 0
            }
        )

    # -----------------------------------------

    async def get_by_id(
        self,
        user_id: str,
    ) -> Optional[dict]:

        return await db.users.find_one(
            {
                "id": user_id
            },
            {
                "_id": 0
            }
        )

    async def get_by_identifier(
        self,
        identifier: str,
    ) -> Optional[dict]:
        value = identifier.strip().lower()
        clauses = [
            {"email": value},
            {"username": value},
        ]
        try:
            phone = normalize_phone(identifier)
            clauses.extend([{"phone": phone}, {"whatsapp": phone}])
        except ValueError:
            pass
        return await db.users.find_one(
            {"$or": clauses},
            {"_id": 0},
        )
        
    
    # -----------------------------------------

    async def register_application(
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
            "created_at": datetime.utcnow().isoformat(),
        }

        existing = await db.applications.find_one(
            {"email": payload.email.lower()}
        )

        if existing:
            raise Exception("Application already exists.")

        await db.applications.insert_one(document)

        document.pop("_id", None)

        return document
    
    
    async def approve_application(
    self,
    application_id: str,
):

        application = await db.applications.find_one(
            {"id": application_id}
        )

        if not application:
            return None

        await db.applications.update_one(
            {"id": application_id},
            {
                "$set": {
                    "status": "APPROVED"
                }
            }
        )

        return True

    async def reject_application(
        self,
        application_id: str,
    ):

        await db.applications.update_one(
            {"id": application_id},
            {
                "$set": {
                    "status": "REJECTED"
                }
            }
        )

        return True
    # -----------------------------------------

    async def create(
        self,
        document: dict,
    ):

        await db.users.insert_one(document)

        return document

    # -----------------------------------------

    async def update(
        self,
        user_id: str,
        update: dict,
    ):

        await db.users.update_one(
            {
                "id": user_id
            },
            {
                "$set": update
            }
        )

    # -----------------------------------------

    async def exists(
        self,
        email: str,
    ) -> bool:

        user = await self.get_by_email(email)

        return user is not None

    # -----------------------------------------

    async def list_by_company(
        self,
        company_id: str,
    ):

        return await db.users.find(
            {
                "company_id": company_id
            },
            {
                "_id": 0,
                "password_hash": 0,
            }
        ).to_list(1000)

    # -----------------------------------------

    async def block(
        self,
        user_id: str,
    ):

        await self.update(
            user_id,
            {
                "blocked": True
            }
        )

    # -----------------------------------------

    async def unblock(
        self,
        user_id: str,
    ):

        await self.update(
            user_id,
            {
                "blocked": False
            }
        )


user_repository = UserRepository()
