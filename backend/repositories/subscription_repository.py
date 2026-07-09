import uuid

from datetime import datetime,timedelta

from core import db


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

            "max_sites":1,

            "max_supervisors":2,

            "storage_gb":2,

            "trial":True,

            "trial_expiry":(
                datetime.utcnow()+timedelta(days=30)
            ).isoformat(),

            "created_at":datetime.utcnow().isoformat()

        }

        await db.subscriptions.insert_one(
            document.copy()
        )

        return document


subscription_repository=SubscriptionRepository()