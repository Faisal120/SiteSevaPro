from repositories.subscription_repository import (
    subscription_repository,
)


class DesignSubscriptionHelper:

    async def plan(
        self,
        company_id,
    ):

        return await subscription_repository.get_plan(
            company_id
        )

    async def is_free(
        self,
        company_id,
    ):

        return (
            await self.plan(company_id)
        ) == "FREE"

    async def is_pro(
        self,
        company_id,
    ):

        return (
            await self.plan(company_id)
        ) == "PRO"

    async def is_enterprise(
        self,
        company_id,
    ):

        return (
            await self.plan(company_id)
        ) == "ENTERPRISE"


design_subscription_helper = DesignSubscriptionHelper()