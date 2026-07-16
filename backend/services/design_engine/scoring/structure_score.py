class StructureScore:

    def score(

        self,

        rooms,

    ):

        score = 0

        for room in rooms:

            ratio = max(

                room.width,

                room.length,

            ) / min(

                room.width,

                room.length,

            )

            if ratio < 2:

                score += 30

            else:

                score -= 15

        return score


structure_score = StructureScore()