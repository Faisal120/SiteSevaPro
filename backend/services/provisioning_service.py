import secrets
import string
import uuid

from datetime import datetime

from core import hash_password

from repositories.company_repository import company_repository
from repositories.user_repository import user_repository
from repositories.subscription_repository import subscription_repository
from repositories.company_wallet_repository import company_wallet_repository


class ProvisioningService:

    def generate_username(
        self,
        company_name: str,
    ):

        prefix = "".join(
            c
            for c in company_name.upper()
            if c.isalpha()
        )[:4]

        return f"{prefix}{secrets.randbelow(9000)+1000}"

    def generate_password(
        self,
    ):

        chars = string.ascii_letters + string.digits

        return "".join(
            secrets.choice(chars)
            for _ in range(10)
        )

    async def create_company(
        self,
        application,
    ):

        company = {

            "id": str(uuid.uuid4()),

            "name": application["company_name"],

            "owner_id": "",

            "gst_number": application.get("gst_number"),

            "city": application["city"],

            "state": application["state"],

            "address": application["office_address"],

            "created_at": datetime.utcnow().isoformat(),

            "branding": {

                "company_name": application["company_name"],

                "logo_url": None,

                "primary_color": "#2563EB",

                "secondary_color": "#0F172A",

                "phone": application["mobile"],

                "email": application["email"],

            },

        }

        return await company_repository.create(company)

    async def create_contractor(
        self,
        application,
        company,
    ):

        username = self.generate_username(company["name"])

        password = self.generate_password()

        contractor = {

            "id": str(uuid.uuid4()),

            "email": application["email"],

            "username": username,

            "password_hash": hash_password(password),

            "full_name": application["owner_name"],

            "company_id": company["id"],

            "company_name": company["name"],

            "role": "CONTRACTOR",

            "plan": "FREE",

            "blocked": False,

            "must_change_password": True,

            "site_ids": [],

            "created_at": datetime.utcnow().isoformat(),

        }

        contractor = await user_repository.create(contractor)

        await company_repository.update_owner(
            company["id"],
            contractor["id"],
        )

        return contractor, username, password

    async def provision(
        self,
        application,
    ):

        company = await self.create_company(application)

        contractor, username, password = await self.create_contractor(
            application,
            company,
        )

        await subscription_repository.create_free(
            company["id"]
        )

        await company_wallet_repository.create(
            company["id"]
        )

        return {

            "company": company,

            "contractor": contractor,

            "username": username,

            "temporary_password": password,

        }


provisioning_service = ProvisioningService()