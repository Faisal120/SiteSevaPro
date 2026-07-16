
class AdjacencySolver:

    ORDER = [

        "Parking",

        "Entrance",

        "Living",

        "Dining",

        "Kitchen",

        "Stair",

        "Bedroom",

        "Bathroom",

        "Garden",

    ]

    def solve(
        self,
        rooms,
    ):

        return sorted(

            rooms,

            key=lambda room:

            self.ORDER.index(room.name)

            if room.name in self.ORDER

            else 100

        )


adjacency_solver = AdjacencySolver()