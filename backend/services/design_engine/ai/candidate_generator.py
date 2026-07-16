import copy

from services.design_engine.geometry_engine import geometry_engine
from services.design_engine.ai.mutations.mutation_manager import (
    mutation_manager,
)


class CandidateGenerator:

    def generate(

        self,

        rooms,

        plot,

        zones,

        count=5,

    ):

        candidates = []

        for index in range(count):

            candidate_rooms = mutation_manager.mutate(

                index,

                rooms,

                plot,

                zones,

            )

            candidate_rooms = geometry_engine.place(

                candidate_rooms,

                plot,

                zones,

            )

            candidates.append(

                candidate_rooms

            )

        return candidates


candidate_generator = CandidateGenerator()