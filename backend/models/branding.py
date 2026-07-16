from pydantic import BaseModel
from typing import Optional


class BrandingUpdate(BaseModel):

    company_name: str

    primary_color: str

    secondary_color: str

    accent_color: str

    font: str

    logo: Optional[str] = None

    favicon: Optional[str] = None

    invoice_logo: Optional[str] = None

    quotation_logo: Optional[str] = None

    stamp: Optional[str] = None

    signature: Optional[str] = None

    website: Optional[str] = None

    email: Optional[str] = None

    phone: Optional[str] = None

    gst_number: Optional[str] = None

    address: Optional[str] = None