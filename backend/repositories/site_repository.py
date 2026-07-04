"""
Site Repository

Only MongoDB operations.

NO Business Logic.

SiteSeva Pro
"""

from core import db
from services.notification_service import (
    notification_service,
)
from typing import List


class SiteRepository:

    # =====================================================
    # Site CRUD
    # =====================================================

    async def list(self, query: dict):

        return await (
            db.sites
            .find(
                query,
                {"_id": 0},
            )
            .sort(
                "created_at",
                -1,
            )
            .to_list(500)
        )

    async def get(
    self,
    site_id: str,
    projection: dict | None = None,
):

        if projection is None:
            projection = {"_id": 0}

        return await db.sites.find_one(
            {
                "id": site_id
            },
            projection,
        )

    async def create(
        self,
        document: dict,
    ):

        await db.sites.insert_one(document)

        return document

    async def update(
        self,
        site_id: str,
        company_id: str,
        payload: dict,
    ):

        return await db.sites.update_one(
            {
                "id": site_id,
                "company_id": company_id,
            },
            {
                "$set": payload
            },
        )

    async def delete(
        self,
        site_id: str,
        company_id: str,
    ):

        return await db.sites.delete_one(
            {
                "id": site_id,
                "company_id": company_id,
            }
        )

    # =====================================================
    # Subscription
    # =====================================================

    async def active_subscription(
        self,
        company_id: str,
    ):

        return await db.subscriptions.find_one(
            {
                "company_id": company_id,
                "status": "ACTIVE",
            }
        )

    async def company_site_count(
        self,
        company_id: str,
    ):

        return await db.sites.count_documents(
            {
                "company_id": company_id,
            }
        )

    # =====================================================
    # Users
    # =====================================================

    async def get_user(
        self,
        query: dict,
    ):

        return await db.users.find_one(query)

    async def update_user(
        self,
        user_id: str,
        payload: dict,
    ):

        return await db.users.update_one(
            {
                "id": user_id
            },
            {
                "$set": payload
            }
        )

    async def add_site_to_user(
        self,
        user_id: str,
        site_id: str,
    ):

        return await db.users.update_one(
            {
                "id": user_id
            },
            {
                "$addToSet": {
                    "site_ids": site_id
                }
            }
        )

    # =====================================================
    # Tasks
    # =====================================================

    async def create_task(
        self,
        document: dict,
    ):

        await db.site_tasks.insert_one(document)

    async def create_tasks(
        self,
        documents: list,
    ):

        if documents:

            await db.site_tasks.insert_many(
                documents
            )
            
    # =====================================================
    # Supervisor
    # =====================================================

    async def update_supervisors(
        self,
        site_id: str,
        supervisor_ids: List[str],
        supervisor_names: List[str],
    ):

        return await db.sites.update_one(
            {
                "id": site_id
            },
            {
                "$set": {
                    "supervisor_ids": supervisor_ids,
                    "supervisor_names": supervisor_names,
                }
            }
            
        )
        
        

    # =====================================================
    # Client
    # =====================================================

    async def update_client(
        self,
        site_id: str,
        client_id: str,
        client_name: str,
        client_email: str,
    ):

        return await db.sites.update_one(
            {
                "id": site_id
            },
            {
                "$set": {
                    "client_id": client_id,
                    "client_name": client_name,
                    "client_email": client_email,
                }
            }
        )

    # =====================================================
    # BULK USERS
    # =====================================================

    async def get_supervisors(
        self,
        company_id: str,
        supervisor_ids: list[str],
    ):

        return await db.users.find(
            {
                "company_id": company_id,
                "role": "SUPERVISOR",
                "id": {
                    "$in": supervisor_ids
                },
            },
            {
                "_id": 0
            },
        ).to_list(100)
        
        


    async def get_client(
        self,
        company_id: str,
        client_id: str,
    ):

        return await db.users.find_one(
            {
                "company_id": company_id,
                "role": "CLIENT",
                "id": client_id,
            },
            {
                "_id": 0
            },
        )
        
    # =====================================================
    # TASKS
    # =====================================================

    async def bulk_create_tasks(
        self,
        documents: list,
    ):

        if not documents:
            return

        await db.site_tasks.insert_many(
            documents
        )
    
site_repository = SiteRepository()