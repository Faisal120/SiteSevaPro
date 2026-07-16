class PackingCost:

    def evaluate(
        self,
        packed_rooms,
    ):

        overlap = 0
        empty = 0

        for i in range(len(packed_rooms)):

            for j in range(i + 1, len(packed_rooms)):

                overlap += self._overlap(
                    packed_rooms[i],
                    packed_rooms[j],
                )

        return overlap * 1000 + empty

    def _overlap(
        self,
        a,
        b,
    ):

        dx = min(
            a.x + a.width,
            b.x + b.width,
        ) - max(
            a.x,
            b.x,
        )

        dy = min(
            a.y + a.height,
            b.y + b.height,
        ) - max(
            a.y,
            b.y,
        )

        if dx <= 0 or dy <= 0:
            return 0

        return dx * dy


packing_cost = PackingCost()