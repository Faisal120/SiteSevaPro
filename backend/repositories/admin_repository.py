from core.database import db


class AdminRepository:

    # ============================================
    # Companies
    # ============================================

    async def total_companies(self):

        return await db.companies.count_documents({})

    async def active_companies(self):

        return await db.companies.count_documents(

            {

                "status":"ACTIVE"

            }

        )

    # ============================================
    # Users
    # ============================================

    async def total_users(self):

        return await db.users.count_documents({})

    # ============================================
    # Sites
    # ============================================

    async def total_sites(self):

        return await db.sites.count_documents({})

    # ============================================
    # Subscriptions
    # ============================================

    async def active_subscriptions(self):

        return await db.subscriptions.count_documents(

            {

                "status":"ACTIVE"

            }

        )

    # ============================================
    # Revenue
    # ============================================

    async def subscription_revenue(self):

        pipeline=[

            {

                "$match":{

                    "status":"ACTIVE"

                }

            },

            {

                "$group":{

                    "_id":None,

                    "amount":{

                        "$sum":"$amount"

                    }

                }

            }

        ]

        result=await db.subscriptions.aggregate(

            pipeline

        ).to_list(1)

        if result:

            return result[0]["amount"]

        return 0


    # ==========================================================
    # CONTRACTORS
    # ==========================================================

    async def contractors(

        self,

        skip: int = 0,

        limit: int = 20,

    ):

        return await (

            db.users

            .find(

                {

                    "role": "CONTRACTOR"

                },

                {

                    "_id": 0,

                    "password": 0,

                }

            )

            .sort(

                "created_at",

                -1,

            )

            .skip(skip)

            .limit(limit)

            .to_list(limit)

        )


    async def contractor(

        self,

        contractor_id: str,

    ):

        return await db.users.find_one(

            {

                "id": contractor_id,

                "role": "CONTRACTOR",

            },

            {

                "_id": 0,

                "password": 0,

            }

        )
        
    # ==========================================================
    # ACTIVATE / SUSPEND
    # ==========================================================

    async def update_status(

        self,

        contractor_id,

        status,

    ):

        return await db.users.update_one(

            {

                "id": contractor_id,

                "role": "CONTRACTOR",

            },

            {

                "$set": {

                    "status": status

                }

            }

        )
        
    async def subscription(

        self,

        contractor_id,

    ):

        return await db.subscriptions.find_one(

            {

                "company_id": contractor_id,

                "status": "ACTIVE",

            },

            {

                "_id": 0

            }

        )
        
    async def statistics(

        self,

        company_id,

    ):

        sites = await db.sites.count_documents(

            {

                "company_id": company_id

            }

        )

        labour = await db.labour.count_documents(

            {

                "company_id": company_id

            }

        )

        materials = await db.materials.count_documents(

            {

                "company_id": company_id

            }

        )

        users = await db.users.count_documents(

            {

                "company_id": company_id

            }

        )

        return {

            "sites": sites,

            "labour": labour,

            "materials": materials,

            "users": users,

        }
        
    # ==========================================================
    # SUBSCRIPTIONS
    # ==========================================================

    async def subscriptions(

        self,

        skip: int = 0,

        limit: int = 20,

    ):

        return await (

            db.subscriptions

            .find(
                {},
                {
                    "_id": 0,
                }
            )

            .sort(
                "created_at",
                -1,
            )

            .skip(skip)

            .limit(limit)

            .to_list(limit)

        )


    async def subscription_by_company(

        self,

        company_id,

    ):

        return await db.subscriptions.find_one(

            {

                "company_id": company_id,

                "status": "ACTIVE",

            },

            {

                "_id": 0,

            }

        )


    async def save_subscription(

        self,

        company_id,

        document,

    ):

        await db.subscriptions.update_one(

            {

                "company_id": company_id,

            },

            {

                "$set": document,

            },

            upsert=True,

        )

        return document
    
    
    # ==========================================================
    # PLATFORM ANALYTICS
    # ==========================================================

    async def platform_analytics(self):

        pipeline = [

            {
                "$group": {

                    "_id": "$plan",

                    "companies": {

                        "$sum": 1

                    }

                }

            }

        ]

        plans = await db.subscriptions.aggregate(

            pipeline

        ).to_list(None)

        revenue = await self.subscription_revenue()

        active_sites = await db.sites.count_documents(

            {

                "status": "ACTIVE"

            }

        )

        completed_sites = await db.sites.count_documents(

            {

                "status": "COMPLETED"

            }

        )

        labour = await db.labour.count_documents({})

        materials = await db.materials.count_documents({})

        return {

            "plans": plans,

            "revenue": revenue,

            "active_sites": active_sites,

            "completed_sites": completed_sites,

            "labour": labour,

            "materials": materials,

        }
        
        
    # ==========================================================
    # AUDIT LOGS
    # ==========================================================

    async def audit_logs(

        self,

        limit=100,

    ):

        return await (

            db.audit_logs

            .find(

                {},

                {

                    "_id": 0

                }

            )

            .sort(

                "created_at",

                -1

            )

            .limit(limit)

            .to_list(limit)

        )
    
    
admin_repository=AdminRepository()