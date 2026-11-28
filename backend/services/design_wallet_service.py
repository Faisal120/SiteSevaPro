from repositories.design_wallet_repository import (
    design_wallet_repository,
)

from repositories.design_transaction_repository import (
    design_transaction_repository,
)

from repositories.subscription_repository import (
    subscription_repository,
)

from repositories.design_transaction_repository import (
    design_transaction_repository,
)

from design_core.design_constants import (
    FREE_CREDITS,
    PRO_MONTHLY_CREDITS,
    ENTERPRISE_MONTHLY_CREDITS,
)
from services.plan_catalog import canonical_plan, plan_details


class InsufficientCreditsError(Exception):
    """Raised when a billable design operation cannot be funded."""


class DesignWalletService:

    # ==========================================
    # INITIALIZE WALLET
    # ==========================================

    async def initialize(
        self,
        company_id: str,
        plan: str,
    ):

        wallet = await design_wallet_repository.get(
            company_id
        )

        if wallet:
            return wallet

        # The canonical catalog is also used by subscription fulfilment. This
        # keeps legacy PRO records compatible without silently giving Premium
        # customers free-plan credits.
        credits = plan_details(canonical_plan(plan))["monthly_design_credits"]

        wallet = await design_wallet_repository.create(
            {
                "company_id": company_id,
                "credits": credits,
            }
        )

        await design_transaction_repository.create(
            {
                "company_id": company_id,
                "type": "WELCOME",
                "credits": credits,
                "description": "Welcome Credits",
            }
        )

        return wallet

    # ==========================================

    async def balance(
        self,
        company_id: str,
    ):
        wallet = await design_wallet_repository.get(company_id)

        if wallet is None:
            plan = await subscription_repository.get_plan(company_id)
            wallet = await self.initialize(company_id, plan)

        return wallet

    # ==========================================

    async def consume(
    self,
    company_id: str,
    credits: int,
    reason: str,
):

        wallet = await design_wallet_repository.get(
            company_id
        )

        # Auto-create wallet if missing
        if wallet is None:

            plan = await subscription_repository.get_plan(
                company_id
            )

            wallet = await self.initialize(
                company_id,
                plan,
            )

        result = await design_wallet_repository.deduct_credits(
            company_id,
            credits,
        )

        if result.modified_count == 0:
            raise InsufficientCreditsError(
                "Insufficient credits."
            )

        await design_transaction_repository.create(
            {
                "company_id": company_id,
                "credits": -credits,
                "type": "USAGE",
                "description": reason,
            }
        )

    # ==========================================

    async def add(
        self,
        company_id,
        credits,
        reason,
    ):

        await design_wallet_repository.add_credits(
            company_id,
            credits,
        )

        await design_transaction_repository.create(
            {
                "company_id": company_id,
                "credits": credits,
                "type": "PURCHASE",
                "description": reason,
            }
        )

    async def refund(
        self,
        company_id: str,
        credits: int,
        reason: str,
    ):
        await design_wallet_repository.add_credits(company_id, credits)
        await design_transaction_repository.create(
            {
                "company_id": company_id,
                "credits": credits,
                "type": "REFUND",
                "description": reason,
            }
        )

    async def transactions(
        self,
        company_id,
    ):

        return await design_transaction_repository.list(
            company_id
        )

design_wallet_service = DesignWalletService()
