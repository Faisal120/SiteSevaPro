from typing import Literal

from pydantic import BaseModel


SubscriptionPlan = Literal[
    "FREE",
    "PRO",
    "PREMIUM",
    "ENTERPRISE",
]


BillingCycle = Literal[
    "MONTHLY",
    "YEARLY",
]


class SubscriptionUpdate(BaseModel):

    plan: SubscriptionPlan

    amount: float

    billing_cycle: BillingCycle

    start_date: str

    end_date: str