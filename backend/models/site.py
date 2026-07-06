"""
Site Models

SiteSeva Pro
Production Ready
"""

from typing import Literal, Optional

from pydantic import BaseModel, Field


# ==========================================================
# Site Create / Update
# ==========================================================

class SiteIn(BaseModel):

    # Basic Details
    name: str
    location: str
    budget: float
    start_date: str
    end_date: str

    description: Optional[str] = None
    cover_image: Optional[str] = None

    # Construction
    floors: int = 1

    has_boring: bool = False
    has_septic_tank: bool = True
    has_soak_pit: bool = True
    has_mumty: bool = True

    # Team
    supervisor_ids: list[str] = Field(default_factory=list)

    client_id: Optional[str] = None

    # Status

    status: Literal[
        "PLANNING",
        "ACTIVE",
        "ON_HOLD",
        "COMPLETED",
    ] = "ACTIVE"

    progress: int = 0


# ==========================================================
# Assignment
# ==========================================================

class SiteAssignmentIn(BaseModel):

    user_id: str


# ==========================================================
# Site Card
# ==========================================================

class SiteSummary(BaseModel):

    id: str

    name: str

    location: str

    status: str

    progress: int

    cover_image: Optional[str] = None

    supervisor_names: list[str] = Field(default_factory=list)

    client_name: Optional[str] = None

    last_activity: Optional[str] = None


# ==========================================================
# Site Detail
# ==========================================================

class SiteDetail(BaseModel):

    # -----------------------------------------------------
    # Identity
    # -----------------------------------------------------

    id: str

    # -----------------------------------------------------
    # Ownership
    # -----------------------------------------------------

    company_id: str

    contractor_id: str

    created_by: str

    owner_id: str

    # -----------------------------------------------------
    # Audit
    # -----------------------------------------------------

    created_at: str

    updated_at: str

    # -----------------------------------------------------
    # Basic Details
    # -----------------------------------------------------

    name: str

    location: str

    budget: float

    start_date: str

    end_date: str

    description: Optional[str] = None

    cover_image: Optional[str] = None

    # -----------------------------------------------------
    # Status
    # -----------------------------------------------------

    status: str

    progress: int

    last_activity: Optional[str] = None

    # -----------------------------------------------------
    # Construction
    # -----------------------------------------------------

    floors: int

    has_boring: bool

    has_septic_tank: bool

    has_soak_pit: bool

    has_mumty: bool

    # -----------------------------------------------------
    # Team
    # -----------------------------------------------------

    supervisor_ids: list[str] = Field(default_factory=list)

    supervisor_names: list[str] = Field(default_factory=list)

    client_id: Optional[str] = None

    client_ids: list[str] = Field(default_factory=list)

    client_name: Optional[str] = None

    client_email: Optional[str] = None

    # -----------------------------------------------------
    # Dashboard Metrics
    # -----------------------------------------------------

    labour_count: int = 0

    today_attendance: int = 0

    completed_tasks: int = 0

    pending_tasks: int = 0

    expense: float = 0

    material_cost: float = 0

    labour_cost: float = 0

    other_cost: float = 0

    total_cost: float = 0