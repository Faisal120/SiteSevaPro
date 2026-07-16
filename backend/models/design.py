from pydantic import BaseModel
from typing import Optional
from typing import Dict


class DesignCreate(BaseModel):

    project_name: str

    site_id: Optional[str] = None

    design_type: str

    plot_width: float

    plot_length: float

    facing: str

    floors: int

    bedrooms: int

    bathrooms: int

    kitchen: int = 1

    parking: bool = False

    garden: bool = False

    purpose: str = "RESIDENTIAL"


class DesignResponse(BaseModel):

    id: str

    project_name: str

    status: str

    design_type: str

    credits_used: int