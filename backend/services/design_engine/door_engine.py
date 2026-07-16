"""
Door Engine

Automatically places doors
between adjacent rooms.

No AI.

Production Ready.
"""

from dataclasses import dataclass


@dataclass
class Door:

    x: float

    y: float

    width: float

    wall: str

    room_a: str

    room_b: str


class DoorEngine:

    STANDARD_WIDTH = 3.0

    # =======================================================
    # PUBLIC
    # =======================================================

    def generate(
        self,
        rooms,
    ):

        doors = []

        total = len(rooms)

        for i in range(total):

            for j in range(i + 1, total):

                room_a = rooms[i]

                room_b = rooms[j]

                wall = self._shared_wall(

                    room_a,

                    room_b,

                )

                if wall is None:

                    continue

                doors.append(

                    self._create_door(

                        room_a,

                        room_b,

                        wall,

                    )

                )

        return doors

    # =======================================================
    # SHARED WALL
    # =======================================================

    def _shared_wall(

        self,

        room_a,

        room_b,

    ):

        tolerance = 0.50

        # East-West

        if abs(

            (room_a.x + room_a.width)

            - room_b.x

        ) <= tolerance:

            if self._vertical_overlap(

                room_a,

                room_b,

            ):

                return "EAST"

        if abs(

            (room_b.x + room_b.width)

            - room_a.x

        ) <= tolerance:

            if self._vertical_overlap(

                room_a,

                room_b,

            ):

                return "WEST"

        # North-South

        if abs(

            (room_a.y + room_a.length)

            - room_b.y

        ) <= tolerance:

            if self._horizontal_overlap(

                room_a,

                room_b,

            ):

                return "SOUTH"

        if abs(

            (room_b.y + room_b.length)

            - room_a.y

        ) <= tolerance:

            if self._horizontal_overlap(

                room_a,

                room_b,

            ):

                return "NORTH"

        return None

    # =======================================================
    # OVERLAP
    # =======================================================

    def _vertical_overlap(

        self,

        a,

        b,

    ):

        top = max(

            a.y,

            b.y,

        )

        bottom = min(

            a.y + a.length,

            b.y + b.length,

        )

        return bottom > top

    def _horizontal_overlap(

        self,

        a,

        b,

    ):

        left = max(

            a.x,

            b.x,

        )

        right = min(

            a.x + a.width,

            b.x + b.width,

        )

        return right > left

    # =======================================================
    # CREATE
    # =======================================================

    def _create_door(

        self,

        room_a,

        room_b,

        wall,

    ):

        if wall in (

            "EAST",

            "WEST",

        ):

            y = (

                max(

                    room_a.y,

                    room_b.y,

                )

                +

                min(

                    room_a.y + room_a.length,

                    room_b.y + room_b.length,

                )

            ) / 2

            if wall == "EAST":

                x = room_a.x + room_a.width

            else:

                x = room_a.x

        else:

            x = (

                max(

                    room_a.x,

                    room_b.x,

                )

                +

                min(

                    room_a.x + room_a.width,

                    room_b.x + room_b.width,

                )

            ) / 2

            if wall == "SOUTH":

                y = room_a.y + room_a.length

            else:

                y = room_a.y

        return Door(

            x=x,

            y=y,

            width=self.STANDARD_WIDTH,

            wall=wall,

            room_a=room_a.name,

            room_b=room_b.name,

        )

    # =======================================================
    # EXPORT
    # =======================================================

    def to_json(

        self,

        doors,

    ):

        return [

            {

                "x": d.x,

                "y": d.y,

                "width": d.width,

                "wall": d.wall.lower(),

                "room_a": d.room_a,

                "room_b": d.room_b,

            }

            for d in doors

        ]


door_engine = DoorEngine()