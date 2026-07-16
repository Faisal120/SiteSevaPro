"""
Resize Engine

Reduces room size
until layout fits.
"""

from services.design_engine.room_library import ROOM_LIBRARY


class ResizeEngine:

    def shrink(

        self,

        room,

    ):

        options = ROOM_LIBRARY.get(

            room.name,

            {},

        ).get(

            "sizes",

            [],

        )

        for width, length in reversed(options):

            if (

                width < room.width

                or

                length < room.length

            ):

                room.width = width

                room.length = length

                return room

        return room

    def shrink_all(

        self,

        rooms,

    ):

        for room in rooms:

            self.shrink(room)

        return rooms


resize_engine = ResizeEngine()