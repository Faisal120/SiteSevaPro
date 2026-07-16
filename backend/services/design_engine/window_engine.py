"""
Window Engine

Automatically places windows
on exterior walls only.

Production Ready.
"""

from dataclasses import dataclass


@dataclass
class Window:

    x: float
    y: float
    width: float
    wall: str
    room: str


class WindowEngine:

    WINDOW_WIDTH = 4.0

    # -----------------------------------------------------

    def generate(
        self,
        rooms,
        plot,
    ):

        windows = []

        for room in rooms:

            windows.extend(

                self._room_windows(

                    room,
                    plot,

                )

            )

        return windows

    # -----------------------------------------------------

    def _room_windows(

        self,

        room,

        plot,

    ):

        windows = []

        tol = 0.10

        # NORTH

        if room.y <= tol:

            windows.append(

                Window(

                    x=room.x + room.width / 2,

                    y=room.y,

                    width=self.WINDOW_WIDTH,

                    wall="north",

                    room=room.name,

                )

            )

        # SOUTH

        if room.y + room.length >= plot.length - tol:

            windows.append(

                Window(

                    x=room.x + room.width / 2,

                    y=room.y + room.length,

                    width=self.WINDOW_WIDTH,

                    wall="south",

                    room=room.name,

                )

            )

        # EAST

        if room.x + room.width >= plot.width - tol:

            windows.append(

                Window(

                    x=room.x + room.width,

                    y=room.y + room.length / 2,

                    width=self.WINDOW_WIDTH,

                    wall="east",

                    room=room.name,

                )

            )

        # WEST

        if room.x <= tol:

            windows.append(

                Window(

                    x=room.x,

                    y=room.y + room.length / 2,

                    width=self.WINDOW_WIDTH,

                    wall="west",

                    room=room.name,

                )

            )

        return windows

    # -----------------------------------------------------

    def to_json(

        self,

        windows,

    ):

        return [

            {

                "x": w.x,

                "y": w.y,

                "width": w.width,

                "wall": w.wall,

                "room": w.room,

            }

            for w in windows

        ]


window_engine = WindowEngine()