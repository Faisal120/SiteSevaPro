from dataclasses import dataclass
from typing import List


@dataclass
class Room:

    name: str

    width: float

    length: float

    preferred_zone: str | None = None

    adjacent_to: List[str] | None = None

    avoid: List[str] | None = None

    x: float = 0

    y: float = 0


@dataclass
class Plot:

    width: float

    length: float

    facing: str


@dataclass
class Layout:

    plot: Plot

    rooms: List[Room]