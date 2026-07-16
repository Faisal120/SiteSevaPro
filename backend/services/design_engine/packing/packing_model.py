from dataclasses import dataclass


@dataclass
class PackedRoom:

    room: object

    x: float

    y: float

    width: float

    height: float

    locked: bool = False