from typing import Optional, Literal

from pydantic import BaseModel


PaymentType = Literal[
    "CLIENT_RECEIVED",
    "EXPENSE",
    "LABOUR",
    "MATERIAL",
]


class PaymentIn(BaseModel):

    site_id: str

    type: PaymentType

    amount: float

    description: str

    date: str

    party: Optional[str] = None

    invoice_url: Optional[str] = None