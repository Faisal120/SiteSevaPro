from dataclasses import dataclass, field

from services.design_engine.interior.objects.furniture import (
    Furniture,
)


@dataclass
class InteriorLayoutContext:

    rooms: list

    furniture: list[Furniture] = field(
        default_factory=list
    )