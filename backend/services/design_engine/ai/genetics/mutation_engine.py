import random

from services.design_engine.ai.genetics.mutation_types import (
    MutationType,
)


class MutationEngine:

    def choose(self):

        value = random.random()

        if value < 0.25:
            return MutationType.SWAP

        if value < 0.50:
            return MutationType.SHIFT

        if value < 0.70:
            return MutationType.ROTATE

        if value < 0.85:
            return MutationType.ZONE

        return MutationType.PACKING


mutation_engine = MutationEngine()