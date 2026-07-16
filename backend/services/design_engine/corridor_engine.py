"""
Corridor Engine

Automatically creates corridors between rooms.

Phase 1

Simple Manhattan Corridor.
"""

from dataclasses import dataclass


@dataclass
class Corridor:

    x: float

    y: float

    width: float

    length: float

    direction: str


class CorridorEngine:

    WIDTH = 4.0

    # =====================================================
    # PUBLIC
    # =====================================================

    def generate(
        self,
        rooms,
    ):

        if len(rooms) < 2:

            return []

        rooms = sorted(

            rooms,

            key=lambda room: (

                room.y,

                room.x,

            ),

        )

        corridors = []

        previous = rooms[0]

        for current in rooms[1:]:

            corridors.extend(

                self._connect(

                    previous,

                    current,

                )

            )

            previous = current

        return corridors

    # =====================================================
    # CONNECT
    # =====================================================

    def _connect(

        self,

        room_a,

        room_b,

    ):

        corridors = []

        ax = room_a.x + room_a.width / 2

        ay = room_a.y + room_a.length / 2

        bx = room_b.x + room_b.width / 2

        by = room_b.y + room_b.length / 2

        # Horizontal

        if ax != bx:

            x = min(ax, bx)

            width = abs(ax - bx)

            corridors.append(

                Corridor(

                    x=x,

                    y=ay - self.WIDTH / 2,

                    width=width,

                    length=self.WIDTH,

                    direction="H",

                )

            )

        # Vertical

        if ay != by:

            y = min(ay, by)

            length = abs(ay - by)

            corridors.append(

                Corridor(

                    x=bx - self.WIDTH / 2,

                    y=y,

                    width=self.WIDTH,

                    length=length,

                    direction="V",

                )

            )

        return corridors

    # =====================================================
    # EXPORT
    # =====================================================

    def to_json(

        self,

        corridors,

    ):

        return [

            {

                "x": c.x,

                "y": c.y,

                "width": c.width,

                "height": c.length,

                "direction": c.direction,

            }

            for c in corridors

        ]


corridor_engine = CorridorEngine()