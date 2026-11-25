import uuid

from datetime import datetime, timedelta, timezone

from core import db
from services.plan_catalog import canonical_plan, plan_details


class SubscriptionRepository:

    async def create_free(
        self,
        company_id:str,
    ):

        document={

            "id":str(uuid.uuid4()),

            "company_id":company_id,

            "plan":"FREE",

            "status":"ACTIVE",

            "max_sites": plan_details("FREE")["max_sites"],

            "max_supervisors": plan_details("FREE")["max_supervisors"],

            "storage_gb": plan_details("FREE")["storage_gb"],

            "trial":True,

            "trial_expiry": (datetime.now(timezone.utc) + timedelta(days=plan_details("FREE")["trial_days"])).isoformat(),
            "expires_at": (datetime.now(timezone.utc) + timedelta(days=plan_details("FREE")["trial_days"])).isoformat(),

            "created_at":datetime.utcnow().isoformat()

        }

        await db.subscriptions.insert_one(
            document.copy()
        )

        return document
    
    async def get_active(
        self,
        company_id: str,
    ):

        subscription = await db.subscriptions.find_one(

            {
                "company_id": company_id,
                "status": "ACTIVE",
            },

            {
                "_id": 0,
            },

        )
        if not subscription:
            return None
        expiry = subscription.get("expires_at") or subscription.get("trial_expiry")
        if expiry and str(expiry) <= datetime.now(timezone.utc).isoformat():
            await db.subscriptions.update_one(
                {"id": subscription.get("id"), "status": "ACTIVE"},
                {"$set": {"status": "EXPIRED", "expired_at": datetime.now(timezone.utc).isoformat()}},
            )
            return None
        subscription["plan"] = canonical_plan(subscription.get("plan"))
        return subscription

    async def get_plan(
        self,
        company_id: str,
    ):

        subscription = await self.get_active(
            company_id
        )

        if subscription:

            return subscription["plan"]

        return "FREE"
    
    


subscription_repository=SubscriptionRepository()
