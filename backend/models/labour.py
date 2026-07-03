from typing import Optional

from pydantic import BaseModel


class LabourIn(BaseModel):

    full_name: str

    mobile: Optional[str] = None

    trade: str

    daily_wage: float

    site_id: str

    aadhaar: Optional[str] = None

    address: Optional[str] = None


class AttendanceIn(BaseModel):

    labour_id: str

    site_id: str

    status: str

    overtime_hours: float = 0