import uuid

from datetime import datetime

from core import db


class CompanyWalletRepository:

    async def create(
        self,
        company_id,
    ):

        document={

            "id":str(uuid.uuid4()),

            "company_id":company_id,

            "balance":0,

            "credit":0,

            "debit":0,

            "created_at":datetime.utcnow().isoformat()

        }

        await db.wallets.insert_one(
            document.copy()
        )

        return document


company_wallet_repository=CompanyWalletRepository()