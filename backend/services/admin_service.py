from repositories.admin_repository import (

    admin_repository

)


class AdminService:

    async def dashboard(

        self,

    ):

        companies=await admin_repository.total_companies()

        active=await admin_repository.active_companies()

        users=await admin_repository.total_users()

        sites=await admin_repository.total_sites()

        subscriptions=await admin_repository.active_subscriptions()

        revenue=await admin_repository.subscription_revenue()

        return{

            "companies":companies,

            "active_companies":active,

            "users":users,

            "sites":sites,

            "subscriptions":subscriptions,

            "monthly_revenue":revenue,

        }

    # ==========================================================
    # CONTRACTORS
    # ==========================================================

    async def contractors(

        self,

        page=1,

        limit=20,

    ):

        skip = (page - 1) * limit

        return await admin_repository.contractors(

            skip,

            limit,

        )


    async def contractor_details(

        self,

        contractor_id,

    ):

        contractor = await admin_repository.contractor(

            contractor_id

        )

        if contractor is None:

            raise HTTPException(

                404,

                "Contractor not found",

            )

        subscription = await admin_repository.subscription(

            contractor["id"]

        )

        statistics = await admin_repository.statistics(

            contractor["company_id"]

        )

        contractor["subscription"] = subscription

        contractor["statistics"] = statistics

        return contractor

    async def suspend(

        self,

        contractor_id,

    ):

        await admin_repository.update_status(

            contractor_id,

            "SUSPENDED",

        )

        return {

            "success": True

        }
        
    async def activate(

        self,

        contractor_id,

    ):

        await admin_repository.update_status(

            contractor_id,

            "ACTIVE",

        )

        return {

            "success": True

        }
        
        # ==========================================================
    # SUBSCRIPTIONS
    # ==========================================================

    async def subscriptions(

        self,

        page=1,

        limit=20,

    ):

        skip = (page - 1) * limit

        return await admin_repository.subscriptions(

            skip,

            limit,

        )
        
        
    async def upgrade_subscription(

    self,

    company_id,

    body,

):

        subscription = {

            "company_id": company_id,

            "plan": body.plan,

            "status": "ACTIVE",

            "amount": body.amount,

            "billing_cycle": body.billing_cycle,

            "start_date": body.start_date,

            "end_date": body.end_date,

            "updated_at": now_iso(),

        }

        await admin_repository.save_subscription(

            company_id,

            subscription,

        )

        return subscription
    
    
    async def expire_subscription(

    self,

    company_id,

):

        subscription = await admin_repository.subscription_by_company(

            company_id

        )

        if subscription is None:

            raise HTTPException(

                404,

                "Subscription not found",

            )

        subscription["status"] = "EXPIRED"

        subscription["updated_at"] = now_iso()

        await admin_repository.save_subscription(

            company_id,

            subscription,

        )

        return {

            "success": True

        }
        
    # ==========================================================
    # PLATFORM ANALYTICS
    # ==========================================================

    async def analytics(

        self,

    ):

        return await admin_repository.platform_analytics()
    
    
    # ==========================================================
    # AUDIT LOGS
    # ==========================================================

    async def logs(

        self,

    ):

        return await admin_repository.audit_logs()

admin_service=AdminService()