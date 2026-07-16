"""
Detect usable walls inside a room.
"""

from dataclasses import dataclass


@dataclass
class RoomWall:

    name: str

    x: float

    y: float

    length: float

    direction: str


class WallDetector:

    def detect(

        self,

        room,

    ):

        return [

            RoomWall(

                name="TOP",

                x=room.x,

                y=room.y,

                length=room.width,

                direction="H",

            ),

            RoomWall(

                name="BOTTOM",

                x=room.x,

                y=room.y + room.length,

                length=room.width,

                direction="H",

            ),

            RoomWall(

                name="LEFT",

                x=room.x,

                y=room.y,

                length=room.length,

                direction="V",

            ),

            RoomWall(

                name="RIGHT",

                x=room.x + room.width,

                y=room.y,

                length=room.length,

                direction="V",

            ),

        ]


wall_detector = WallDetector()