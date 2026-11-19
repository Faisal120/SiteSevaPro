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
        company_id: str | None = None,
        projection: dict | None = None,
    ):

        if projection is None:
            projection = {"_id": 0}

        query = {
            "id": site_id,
        }

        if company_id:
            query["company_id"] = company_id

        return await db.sites.find_one(
            query,
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

    async def get_user_by_id(
        self,
        company_id: str,
        user_id: str,
    ):

        return await db.users.find_one(
            {
                "company_id": company_id,
                "id": user_id,
            },
            {
                "_id": 0,
            },
        )

    async def get_user_by_email(
        self,
        company_id: str,
        email: str,
    ):
        return await db.users.find_one(
            {
                "company_id": company_id,
                "email": email.lower(),
            },
            {"_id": 0},
        )

    async def get_users_by_ids(
        self,
        company_id: str,
        user_ids: List[str],
    ):
        if not user_ids:
            return []
        return await db.users.find(
            {
                "company_id": company_id,
                "id": {"$in": user_ids},
            },
            {"_id": 0},
        ).to_list(len(user_ids))

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

    async def remove_site_from_user(
        self,
        user_id: str,
        site_id: str,
    ):
        return await db.users.update_one(
            {"id": user_id},
            {"$pull": {"site_ids": site_id}},
        )
        
    async def count(
        self,
        query: dict,
    ):

        return await db.sites.count_documents(
            query
        )
        
    async def aggregate(
        self,
        pipeline: list,
    ):

        return await db.sites.aggregate(
            pipeline
        ).to_list(None)

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
        company_id: str,    
        supervisor_ids: List[str],
        supervisor_names: List[str],
    ):

        return await db.sites.update_one(
            {
                "id": site_id,
                "company_id": company_id,
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
        company_id: str,
        client_id: str,
        client_ids: List[str],
        client_name: str,
        client_email: str,
    ):

        return await db.sites.update_one(
            {
                "id": site_id,
                "company_id": company_id,
            },
            {
                "$set": {
                    "client_id": client_id,
                    "client_ids": client_ids,
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
        supervisor_ids: List[str],
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
        
    
        # =====================================================
    # Site Queries
    # =====================================================

    async def get_by_company(
        self,
        company_id: str,
    ):

        return await db.sites.find(
            {
                "company_id": company_id,
            },
            {
                "_id": 0,
            },
        ).sort(
            "created_at",
            -1,
        ).to_list(1000)


    async def get_by_company_and_id(
        self,
        company_id: str,
        site_id: str,
    ):

        return await db.sites.find_one(
            {
                "company_id": company_id,
                "id": site_id,
            },
            {
                "_id": 0,
            },
        )


    async def get_for_supervisor(
        self,
        company_id: str,
        supervisor_id: str,
        legacy_site_ids: List[str] | None = None,
    ):

        query = {
            "company_id": company_id,
            "$or": [
                {"supervisor_ids": supervisor_id},
                {"supervisor_id": supervisor_id},
            ],
        }
        if legacy_site_ids:
            query["$or"].append({
                "$and": [
                    {"supervisor_ids": {"$exists": False}},
                    {"supervisor_id": {"$exists": False}},
                    {"id": {"$in": legacy_site_ids}},
                ],
            })

        return await db.sites.find(
            query,
            {
                "_id": 0,
            },
        ).sort(
            "created_at",
            -1,
        ).to_list(1000)


    async def get_for_client(
        self,
        company_id: str,
        client_id: str,
        client_email: str | None = None,
        legacy_site_ids: List[str] | None = None,
    ):

        assignments = [
            {"client_ids": client_id},
            {"client_id": client_id},
        ]
        if client_email:
            assignments.append({"client_email": client_email.lower()})
        if legacy_site_ids:
            assignments.append({
                "$and": [
                    {"client_ids": {"$exists": False}},
                    {"client_id": {"$exists": False}},
                    {"client_email": {"$exists": False}},
                    {"id": {"$in": legacy_site_ids}},
                ],
            })

        return await db.sites.find(
            {
                "company_id": company_id,
                "$or": assignments,
            },
            {
                "_id": 0,
            },
        ).sort(
            "created_at",
            -1,
        ).to_list(1000)


    async def exists(
        self,
        company_id: str,
        site_id: str,
    ):

        return await db.sites.find_one(
            {
                "company_id": company_id,
                "id": site_id,
            },
            {
                "_id": 1,
            },
        )


    async def bulk_get(
        self,
        company_id: str,
        site_ids: List[str],
    ):

        return await db.sites.find(
            {
                "company_id": company_id,
                "id": {
                    "$in": site_ids,
                },
            },
            {
                "_id": 0,
            },
        ).to_list(1000)
    
site_repository = SiteRepository()
