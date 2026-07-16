"""
Layout Optimizer
"""

from services.design_engine.optimizer.mutations import (
    layout_mutation,
)

from services.design_engine.optimizer.annealing import (
    annealing,
)


class LayoutOptimizer:

    ITERATIONS = 250

    START_TEMP = 100

    COOLING = 0.97

    # ------------------------------------------------

    def optimize(

        self,

        rooms,

        graph_builder,

        validator,

        scorer,

        zones,

    ):

        graph = graph_builder.build(rooms)

        current = scorer.evaluate(

            rooms,

            graph,

            zones,

        )

        best = current

        temperature = self.START_TEMP

        for _ in range(self.ITERATIONS):

            candidate_rooms = layout_mutation.mutate(

                current.rooms

            )

            graph = graph_builder.build(

                candidate_rooms

            )

            if not validator.validate(graph):

                continue

            candidate = scorer.evaluate(

                candidate_rooms,

                graph,

                zones,

            )

            if annealing.accept(

                current.score,

                candidate.score,

                temperature,

            ):

                current = candidate

            if candidate.score > best.score:

                best = candidate

            temperature *= self.COOLING

            if temperature < 0.01:

                break

        return best


layout_optimizer = LayoutOptimizer()