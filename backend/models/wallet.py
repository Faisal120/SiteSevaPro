from typing import Optional, Literal

from pydantic import BaseModel, Field


LedgerType = Literal[
    "EARNING",
    "ADVANCE",
    "PAYMENT",
    "BONUS",
    "DEDUCTION",
]


PaymentMode = Literal[
    "CASH",
    "UPI",
    "BANK",
    "CHEQUE",
]


class LabourWallet(BaseModel):

    id: str

    company_id: str

    labour_id: str

    site_id: Optional[str] = None

    earned: float = 0

    advance: float = 0

    paid: float = 0

    bonus: float = 0

    deduction: float = 0

    balance: float = 0

    updated_at: str


class LabourLedger(BaseModel):

    id: str

    company_id: str

    labour_id: str

    site_id: Optional[str] = None

    type: LedgerType

    amount: float

    note: Optional[str] = None

    date: str

    ref_type: Optional[str] = None

    ref_id: Optional[str] = None

    created_at: str


class WalletSettlementIn(BaseModel):

    labour_id: str

    amount: float = Field(gt=0)

    payment_mode: PaymentMode

    remarks: Optional[str] = None


class PayrollIn(BaseModel):

    labour_id: str

    month: str


class PayrollOut(BaseModel):

    labour_id: str

    labour_name: Optional[str] = None

    month: str

    earned: float

    advance: float

    paid: float

    bonus: float

    deduction: float

    balance: float