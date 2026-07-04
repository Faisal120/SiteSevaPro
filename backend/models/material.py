from typing import Optional, Literal

from pydantic import BaseModel


class MaterialIn(BaseModel):
    site_id: str
    name: str
    category: Literal["Cement", "Steel", "Sand", "Bricks", "Electrical", "Plumbing", "Tiles", "Paint", "Other"]
    unit: str
    stock: float = 0
    low_stock_threshold: float = 10
    rate: float = 0

class MaterialTxnIn(BaseModel):
    material_id: str
    site_id: str
    type: Literal["INWARD", "OUTWARD"]
    quantity: float
    rate: Optional[float] = None
    vendor: Optional[str] = None
    note: Optional[str] = None
    invoice_url: Optional[str] = None