from typing import List, Literal, Optional

from pydantic import BaseModel


AttendanceStatus = Literal[
    "PRESENT",
    "HALF_DAY",
    "ABSENT",
    "LEAVE",
    
]


class AttendanceEntry(BaseModel):

    labour_id: str

    status: AttendanceStatus

    overtime_hours: float = 0

    advance: float = 0


class AttendanceIn(BaseModel):

    site_id: str

    date: str

    entries: List[AttendanceEntry]