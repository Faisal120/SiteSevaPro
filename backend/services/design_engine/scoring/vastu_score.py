class VastuScore:

    def score(

        self,

        rooms,

        zones,

    ):

        score = 0

        for room in rooms:

            zone = zones.get(

                room.preferred_zone,

            )

            if zone is None:

                continue

            cx = room.x + room.width / 2

            cy = room.y + room.length / 2

            if (

                zone.x <= cx <= zone.x + zone.width

                and

                zone.y <= cy <= zone.y + zone.height

            ):

                score += 40

            else:

                score -= 20

        return score


vastu_score = VastuScore()