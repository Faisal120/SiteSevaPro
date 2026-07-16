class LightingScore:

    EXTERIOR = {

        "Living",

        "Bedroom",

        "Kitchen",

    }

    def score(

        self,

        rooms,

    ):

        score = 0

        for room in rooms:

            if room.name in self.EXTERIOR:

                if (

                    room.x == 0

                    or

                    room.y == 0

                ):

                    score += 40

                else:

                    score += 10

        return score


lighting_score = LightingScore()