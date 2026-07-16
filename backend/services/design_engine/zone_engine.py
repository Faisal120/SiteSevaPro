"""
Zone Engine

Divides the plot into architectural zones.

Zones:

+---------+---------+---------+
|   NW    |    N    |   NE    |
+---------+---------+---------+
|    W    | CENTER  |    E    |
+---------+---------+---------+
|   SW    |    S    |   SE    |
+---------+---------+---------+

Each room has a preferred zone
(Vastu or Planning Rules)

The Geometry Engine only searches
inside that zone.
"""

from dataclasses import dataclass


# ============================================================
# Zone
# ============================================================

@dataclass
class Zone:

    name: str

    x: float

    y: float

    width: float

    height: float


# ============================================================
# Engine
# ============================================================

class ZoneEngine:

    # --------------------------------------------------------

    def build(
        self,
        plot,
    ):

        third_width = plot.width / 3

        third_height = plot.length / 3

        return {

            "NW": Zone(

                "NW",

                0,

                0,

                third_width,

                third_height,

            ),

            "N": Zone(

                "N",

                third_width,

                0,

                third_width,

                third_height,

            ),

            "NE": Zone(

                "NE",

                third_width * 2,

                0,

                third_width,

                third_height,

            ),

            "W": Zone(

                "W",

                0,

                third_height,

                third_width,

                third_height,

            ),

            "CENTER": Zone(

                "CENTER",

                third_width,

                third_height,

                third_width,

                third_height,

            ),

            "E": Zone(

                "E",

                third_width * 2,

                third_height,

                third_width,

                third_height,

            ),

            "SW": Zone(

                "SW",

                0,

                third_height * 2,

                third_width,

                third_height,

            ),

            "S": Zone(

                "S",

                third_width,

                third_height * 2,

                third_width,

                third_height,

            ),

            "SE": Zone(

                "SE",

                third_width * 2,

                third_height * 2,

                third_width,

                third_height,

            ),

        }

    # --------------------------------------------------------

    def preferred_zone(
        self,
        room,
        zones,
    ):

        zone = room.preferred_zone

        if zone is None:

            return zones["CENTER"]

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

        return zones.get(

            mapping.get(

                zone,

                "CENTER",

            )

        )

    # --------------------------------------------------------

    def rooms_by_zone(
        self,
        rooms,
        zones,
    ):

        grouped = {

            key: []

            for key in zones.keys()

        }

        for room in rooms:

            zone = self.preferred_zone(

                room,

                zones,

            )

            grouped[zone.name].append(

                room

            )

        return grouped


zone_engine = ZoneEngine()