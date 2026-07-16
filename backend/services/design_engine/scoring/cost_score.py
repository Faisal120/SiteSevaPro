class CostScore:

    def score(

        self,

        rooms,

    ):

        perimeter = 0

        for room in rooms:

            perimeter += (

                room.width

                +

                room.length

            ) * 2

        return -perimeter * 0.25


cost_score = CostScore()