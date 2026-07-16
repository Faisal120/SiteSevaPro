"""
Geometry Engine

Zone Based Placement Engine

Phase 3

No AI.

Pure Geometry.
"""

from math import ceil


class GeometryEngine:

    GAP = 1

    # ============================================================
    # ENTRY
    # ============================================================

    def place(

        self,

        rooms,

        plot,

        zones,

    ):

        grouped = self._group_rooms(

            rooms,

            zones,

        )

        for zone_name, zone_rooms in grouped.items():

            if not zone_rooms:

                continue

            zone = zones[zone_name]

            self._layout_zone(

                zone,

                zone_rooms,

            )

        return rooms

    # ============================================================
    # GROUP
    # ============================================================

    def _group_rooms(

        self,

        rooms,

        zones,

    ):

        grouped = {

            name: []

            for name in zones.keys()

        }

        for room in rooms:

            zone = room.preferred_zone

            if zone is None:

                grouped["CENTER"].append(

                    room

                )

                continue

            zone = zone.upper()

            mapping = {

                "NORTH": "N",

                "SOUTH": "S",

                "EAST": "E",

                "WEST": "W",

                "CENTER": "CENTER",

                "NE": "NE",

                "NW": "NW",

                "SE": "SE",

                "SW": "SW",

            }

            grouped[

                mapping.get(

                    zone,

                    "CENTER",

                )

            ].append(

                room

            )

        return grouped

    # ============================================================
    # LAYOUT
    # ============================================================

    def _layout_zone(

        self,

        zone,

        rooms,

    ):

        cols = ceil(len(rooms) ** 0.5)

        if cols < 1:

            cols = 1

        cell_width = zone.width / cols

        rows = ceil(

            len(rooms) / cols

        )

        cell_height = zone.height / rows

        for index, room in enumerate(rooms):

            row = index // cols

            col = index % cols

            room.x = (

                zone.x

                + col * cell_width

            )

            room.y = (

                zone.y

                + row * cell_height

            )

            room.width = min(

                room.width,

                cell_width - self.GAP,

            )

            room.length = min(

                room.length,

                cell_height - self.GAP,

            )

    # ============================================================
    # DEBUG
    # ============================================================

    def print_layout(

        self,

        rooms,

    ):

        for room in rooms:

            print(

                room.name,

                room.x,

                room.y,

                room.width,

                room.length,

            )


geometry_engine = GeometryEngine()