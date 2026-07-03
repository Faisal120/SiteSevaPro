from typing import List, Optional

from pydantic import BaseModel


class DailyReportIn(BaseModel):

    site_id: str

    date: str

    progress: int

    weather: Optional[str] = None

    notes: Optional[str] = None

    issues: List[str] = []

    completed_tasks: List[str] = []

    next_day_plan: Optional[str] = None

    images: List[str] = []