from typing import List, Optional
from pydantic import BaseModel, Field


class ReportMedia(BaseModel):
    url: str
    public_id: Optional[str] = None
    type: str = "image"


class DailyReportIn(BaseModel):

    site_id: str

    date: str

    progress: int = 0

    weather: Optional[str] = None

    notes: Optional[str] = None

    issues: List[str] = Field(default_factory=list)

    completed_tasks: List[str] = Field(default_factory=list)

    next_day_plan: Optional[str] = None

    media_urls: List[ReportMedia] = Field(default_factory=list)