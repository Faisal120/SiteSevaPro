from core import db


class WalletRepository:

    # =====================================================
    # Wallet
    # =====================================================

    async def get_wallet(
        self,
        labour_id: str,
    ):

        return await db.labour_wallet.find_one(
            {
                "labour_id": labour_id
            },
            {
                "_id": 0
            }
        )


    async def save_wallet(
        self,
        wallet: dict,
    ):

        await db.labour_wallet.update_one(

            {
                "labour_id": wallet["labour_id"]
            },

            {
                "$set": wallet
            },

            upsert=True,

        )

        return wallet


    # =====================================================
    # Ledger
    # =====================================================

    async def ledger(
        self,
        labour_id: str,
    ):

        return await (

            db.labour_ledger

            .find(
                {
                    "labour_id": labour_id
                },
                {
                    "_id": 0
                }
            )

            .sort(
                "date",
                1,
            )

            .to_list(5000)

        )


    async def create_ledger(
        self,
        document: dict,
    ):

        await db.labour_ledger.insert_one(
            document
        )

        return document


    # =====================================================
    # Labour
    # =====================================================

    async def get_labour(
        self,
        labour_id: str,
    ):

        return await db.labour.find_one(

            {
                "id": labour_id
            },

            {
                "_id": 0
            }

        )


    # =====================================================
    # Payroll
    # =====================================================

    async def save_payroll(
        self,
        payroll: dict,
    ):

        await db.payroll.update_one(

            {
                "labour_id": payroll["labour_id"],
                "month": payroll["month"],
            },

            {
                "$set": payroll
            },

            upsert=True,

        )

        return payroll


    async def payrolls(
        self,
        company_id: str,
        month: str,
    ):

        return await (

            db.payroll

            .find(
                {
                    "company_id": company_id,
                    "month": month,
                },
                {
                    "_id": 0
                }
            )

            .sort(
                "labour_name",
                1,
            )

            .to_list(1000)

        )


wallet_repository = WalletRepository()