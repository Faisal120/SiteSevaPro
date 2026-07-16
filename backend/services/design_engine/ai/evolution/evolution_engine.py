from services.design_engine.ai.evolution.selection import (
    selection,
)

from services.design_engine.ai.evolution.crossover import (
    crossover,
)

from services.design_engine.ai.evolution.elite_manager import (
    elite_manager,
)


class EvolutionEngine:

    GENERATIONS = 20

    def evolve(

        self,

        population,

    ):

        current = population

        for _ in range(

            self.GENERATIONS

        ):

            elites = elite_manager.preserve(

                current

            )

            children = []

            while len(children) < len(current):

                p1 = selection.select(

                    current

                )

                p2 = selection.select(

                    current

                )

                child = crossover.cross(

                    p1,

                    p2,

                )

                children.append(

                    child

                )

            current = elites + children

        return current


evolution_engine = EvolutionEngine()