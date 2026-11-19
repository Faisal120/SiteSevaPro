from typing import List, Optional
from dataclasses import dataclass, field

@dataclass
class Room:
    name: str
    room_type: str

    width: float
    length: float

    x: float = 0.0
    y: float = 0.0

    preferred_zone: Optional[str] = None

    adjacent_to: list[str] = field(default_factory=list)
    avoid: list[str] = field(default_factory=list)

    graph_id: Optional[str] = None


@dataclass
class Plot:

    width: float

    length: float

    facing: str


@dataclass
class Layout:

    plot: Plot

    rooms: List[Room]
