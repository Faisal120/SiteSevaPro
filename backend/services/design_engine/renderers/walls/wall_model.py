from dataclasses import dataclass


@dataclass
class Wall:

    x1: float

    y1: float

    x2: float

    y2: float

    thickness: float

    external: bool

    openings: list