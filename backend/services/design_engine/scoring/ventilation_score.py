class VentilationScore:

    def score(

        self,

        rooms,

    ):

        score = 0

        for room in rooms:

            if (

                room.x == 0

                or

                room.y == 0

            ):

                score += 20

        return score


ventilation_score = VentilationScore()