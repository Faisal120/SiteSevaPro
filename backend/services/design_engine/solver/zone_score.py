"""
Zone Score

Checks if room
is inside preferred zone.
"""

class ZoneScore:

    def score(

        self,

        room,

        zones,

    ):

        zone = zones.get(

            room.preferred_zone,

        )

        if zone is None:

            return 0

        cx = room.x + room.width / 2

        cy = room.y + room.length / 2

        if (

            zone.x <= cx <= zone.x + zone.width

            and

            zone.y <= cy <= zone.y + zone.height

        ):

            return 100

        return -100


zone_score = ZoneScore()