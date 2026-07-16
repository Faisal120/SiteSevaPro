from pydantic import BaseModel


class CreditPurchase(BaseModel):

    credits: int