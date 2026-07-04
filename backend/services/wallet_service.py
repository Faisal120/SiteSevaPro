from fastapi import HTTPException

from core import new_id, now_iso

from repositories.wallet_repository import wallet_repository


class WalletService:

    # =====================================================
    # GET WALLET
    # =====================================================

    async def get_wallet(
        self,
        labour_id: str,
        user,
    ):

        labour = await wallet_repository.get_labour(
            labour_id
        )

        if labour is None:
            raise HTTPException(
                status_code=404,
                detail="Labour not found",
            )

        if labour["company_id"] != user["company_id"]:
            raise HTTPException(
                status_code=403,
                detail="Forbidden",
            )

        wallet = await wallet_repository.get_wallet(
            labour_id
        )

        if wallet is None:

            wallet = await self.recompute_wallet(
                labour_id
            )

        return wallet

    # =====================================================
    # LEDGER SUMMARY
    # =====================================================

    async def ledger_summary(
        self,
        labour_id: str,
    ):

        ledger = await wallet_repository.ledger(
            labour_id
        )

        earned = 0
        advance = 0
        paid = 0
        bonus = 0
        deduction = 0

        for item in ledger:

            amount = float(
                item.get(
                    "amount",
                    0,
                )
            )

            txn_type = item.get(
                "type"
            )

            if txn_type == "EARNING":
                earned += amount

            elif txn_type == "ADVANCE":
                advance += amount

            elif txn_type == "PAYMENT":
                paid += amount

            elif txn_type == "BONUS":
                bonus += amount

            elif txn_type == "DEDUCTION":
                deduction += amount

        return {

            "earned": round(
                earned,
                2,
            ),

            "advance": round(
                advance,
                2,
            ),

            "paid": round(
                paid,
                2,
            ),

            "bonus": round(
                bonus,
                2,
            ),

            "deduction": round(
                deduction,
                2,
            ),

        }

    # =====================================================
    # RECOMPUTE WALLET
    # =====================================================

    async def recompute_wallet(
        self,
        labour_id: str,
    ):

        labour = await wallet_repository.get_labour(
            labour_id
        )

        if labour is None:
            raise HTTPException(
                status_code=404,
                detail="Labour not found",
            )

        summary = await self.ledger_summary(
            labour_id
        )

        balance = (

            summary["earned"]

            + summary["bonus"]

            - summary["advance"]

            - summary["paid"]

            - summary["deduction"]

        )

        existing = await wallet_repository.get_wallet(
            labour_id
        )

        wallet = {

            "id": (
                existing["id"]
                if existing
                else new_id()
            ),

            "company_id": labour["company_id"],

            "labour_id": labour_id,

            "site_id": labour.get(
                "site_id"
            ),

            "earned": summary["earned"],

            "advance": summary["advance"],

            "paid": summary["paid"],

            "bonus": summary["bonus"],

            "deduction": summary["deduction"],

            "balance": round(
                balance,
                2,
            ),

            "updated_at": now_iso(),

        }

        await wallet_repository.save_wallet(
            wallet
        )

        return wallet

    # =====================================================
    # SETTLE PAYMENT
    # =====================================================

    async def settle_payment(

        self,

        body,

        user,

    ):

        labour = await wallet_repository.get_labour(

            body.labour_id

        )

        if labour is None:

            raise HTTPException(

                status_code=404,

                detail="Labour not found",

            )

        if labour["company_id"] != user["company_id"]:

            raise HTTPException(

                status_code=403,

                detail="Forbidden",

            )

        ledger = {

            "id": new_id(),

            "company_id": user["company_id"],

            "labour_id": body.labour_id,

            "site_id": labour.get(
                "site_id"
            ),

            "type": "PAYMENT",

            "amount": body.amount,

            "note": body.remarks,

            "payment_mode": body.payment_mode,

            "date": now_iso()[:10],

            "created_at": now_iso(),

        }

        await wallet_repository.create_ledger(

            ledger

        )

        wallet = await self.recompute_wallet(

            body.labour_id

        )

        return {

            "wallet": wallet,

            "ledger": ledger,

        }
        
        
    # =====================================================
    # MONTHLY PAYROLL
    # =====================================================

    async def generate_payroll(

        self,

        labour_id,

        month,

    ):

        labour = await wallet_repository.get_labour(

            labour_id

        )

        if labour is None:

            raise HTTPException(

                404,

                "Labour not found",

            )

        ledger = await wallet_repository.ledger(

            labour_id

        )

        earned = 0

        advance = 0

        paid = 0

        bonus = 0

        deduction = 0

        for row in ledger:

            if not row["date"].startswith(
                month
            ):
                continue

            amount = float(
                row["amount"]
            )

            if row["type"] == "EARNING":

                earned += amount

            elif row["type"] == "ADVANCE":

                advance += amount

            elif row["type"] == "PAYMENT":

                paid += amount

            elif row["type"] == "BONUS":

                bonus += amount

            elif row["type"] == "DEDUCTION":

                deduction += amount

        payroll = {

            "id": new_id(),

            "company_id": labour["company_id"],

            "labour_id": labour_id,

            "labour_name": labour["full_name"],

            "month": month,

            "earned": round(
                earned,
                2,
            ),

            "advance": round(
                advance,
                2,
            ),

            "paid": round(
                paid,
                2,
            ),

            "bonus": round(
                bonus,
                2,
            ),

            "deduction": round(
                deduction,
                2,
            ),

            "balance": round(

                earned

                + bonus

                - advance

                - paid

                - deduction,

                2,

            ),

            "generated_at": now_iso(),

        }

        await wallet_repository.save_payroll(

            payroll

        )

        return payroll
    
    # =====================================================
    # PAYROLL SUMMARY
    # =====================================================

    async def monthly_summary(

        self,

        month,

        user,

    ):

        return await wallet_repository.payrolls(

            user["company_id"],

            month,

        )

wallet_service = WalletService()