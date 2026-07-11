import secrets
import string
import uuid

from datetime import datetime

from core import hash_password

from repositories.company_repository import company_repository
from repositories.user_repository import user_repository
from repositories.subscription_repository import subscription_repository
from repositories.company_wallet_repository import company_wallet_repository
from repositories.notification_repository import notification_repository
from repositories.audit_repository import audit_repository


class ProvisioningService:

    # --------------------------------------------------

    def generate_username(
        self,
        company_name: str,
    ):

        prefix = "".join(

            c

            for c in company_name.upper()

            if c.isalpha()

        )[:6]

        return f"{prefix}{secrets.randbelow(9000)+1000}"

    # --------------------------------------------------

    def generate_password(self):

        chars = (

            string.ascii_letters

            + string.digits

        )

        return "".join(

            secrets.choice(chars)

            for _ in range(10)

        )

    # --------------------------------------------------
    
    async def create_company(
    self,
    application,
):
        company_id = str(uuid.uuid4())

        company = {

            "id": str(uuid.uuid4()),

            "name": application["company_name"],

            "owner_id": "",

            "gst_number": application.get("gst_number"),

            "city": application["city"],

            "state": application["state"],

            "address": application["office_address"],

            "status": "ACTIVE",

            "created_at": datetime.utcnow().isoformat(),

            "branding": {

                "company_name": application["company_name"],
                
                "primary_color": "#2563EB",

                "secondary_color": "#1E293B",

                "currency": "INR",

                "timezone": "Asia/Kolkata",

                "language": "en",

            }

        }

        return await company_repository.create(

            company

        )
    
    
    async def create_contractor(
    self,
    application,
    company,
):
        username = self.generate_username(

            application["company_name"]

        )

        password = self.generate_password()

        contractor = {

            "id": str(uuid.uuid4()),

            "email": application["email"],

            "username": username,

            "password_hash": hash_password(

                password

            ),

            "full_name": application["owner_name"],

            "role": "CONTRACTOR",

            "company_id": company["id"],

            "company_name": company["name"],

            "plan": "FREE",

            "blocked": False,

            "must_change_password": True,

            "site_ids": [],

            "created_at": datetime.utcnow().isoformat()

        }

        contractor = await user_repository.create(

            contractor

        )

        await company_repository.update(

            company["id"],

            {

                "owner_id": contractor["id"]

            }

        )

        return contractor, username, password
    
    async def create_subscription(
    self,
    company_id,
):
        await subscription_repository.create_free(

            company_id

        )
        
        
    async def create_wallet(
    self,
    company_id,
):
        await company_wallet_repository.create(

            company_id

        )
        
    async def create_notification(
    self,
    company,
):
        try:

            await notification_repository.create(

                {

                    "id": str(uuid.uuid4()),

                    "company_id": company["id"],

                    "title": "Welcome to SiteSeva Pro",

                    "message": "Your company has been activated.",

                    "type": "SYSTEM",

                    "created_at": datetime.utcnow().isoformat(),

                }

            )

        except Exception:

            pass
        
        
    async def create_audit(
    self,
    company,
):
        try:

            await audit_repository.log(

                action="COMPANY_PROVISIONED",

                description=f"{company['name']} provisioned."

            )

        except Exception:

            pass
        
    

    async def provision_company(

    self,

    application: dict,

):

        company = await self.create_company(
            application
        )

        contractor, username, password = await self.create_contractor(

            application,

            company,

        )

        await self.create_subscription(
            company["id"]
        )

        await self.create_wallet(
            company["id"]
        )

        await self.create_notification(

            company,

            contractor,

        )

        await self.create_audit(
            company
        )

        return {

            "company": company,

            "contractor": contractor,

            "username": username,

            "temporary_password": password,

        }


provisioning_service = ProvisioningService()