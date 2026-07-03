"""
Site Models

Extracted from main.py

SiteSeva Pro
"""

from typing import List, Literal, Optional

from pydantic import BaseModel


# ==========================================================
# Site Create / Update
# ==========================================================

class SiteIn(BaseModel):

    name: str

    location: str

    budget: float

    start_date: str

    end_date: str

    status: Literal[
        "PLANNING",
        "ACTIVE",
        "ON_HOLD",
        "COMPLETED",
    ] = "ACTIVE"

    progress: int = 0

    description: Optional[str] = None

    supervisor_ids: List[str] = []

    client_id: Optional[str] = None

    cover_image: Optional[str] = None

    floors: int = 1

    has_boring: bool = False

    has_septic_tank: bool = True

    has_soak_pit: bool = True

    has_mumty: bool = True


# ==========================================================
# Site Assignment
# ==========================================================

class SiteAssignmentIn(BaseModel):

    user_id: str
    

"""
Site Response Models
"""

from pydantic import BaseModel


class SiteSummary(BaseModel):

    id: str

    name: str

    location: str

    progress: int

    status: str

    cover_image: str | None = None


class SiteDetail(BaseModel):

    id: str

    company_id: str

    created_by: str

    created_at: str

    name: str

    location: str

    budget: float

    start_date: str

    end_date: str

    progress: int

    status: str

    description: str | None = None

    supervisor_ids: list[str] = []

    supervisor_names: list[str] | None = None

    client_id: str | None = None

    client_name: str | None = None

    client_email: str | None = None

    floors: int

    has_boring: bool

    has_septic_tank: bool

    has_soak_pit: bool

    has_mumty: bool

    cover_image: str | None = None