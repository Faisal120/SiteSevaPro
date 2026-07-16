import random

from services.design_engine.packing.packing_model import PackedRoom

from services.design_engine.packing.packing_cost import packing_cost


class PackingSolver:

    ITERATIONS = 500

    def solve(
        self,
        rooms,
        plot,
    ):

        packed = []

        for room in rooms:

            packed.append(

                PackedRoom(

                    room=room,

                    x=random.uniform(
                        0,
                        plot.width - room.width,
                    ),

                    y=random.uniform(
                        0,
                        plot.length - room.length,
                    ),

                    width=room.width,

                    height=room.length,

                )

            )

        best = packed

        best_cost = packing_cost.evaluate(
            packed
        )

        for _ in range(self.ITERATIONS):

            candidate = self._mutate(best, plot)

            cost = packing_cost.evaluate(
                candidate
            )

            if cost < best_cost:

                best = candidate

                best_cost = cost

        return best

    def _mutate(
        self,
        packed,
        plot,
    ):

        import copy

        candidate = copy.deepcopy(
            packed
        )

        room = random.choice(candidate)

        room.x += random.uniform(-2, 2)

        room.y += random.uniform(-2, 2)

        room.x = max(
            0,
            min(
                room.x,
                plot.width - room.width,
            ),
        )

        room.y = max(
            0,
            min(
                room.y,
                plot.length - room.height,
            ),
        )

        return candidate


packing_solver = PackingSolver()