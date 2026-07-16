import copy
import random

from services.design_engine.ai.genetics.mutation_engine import (
    mutation_engine,
)

from .room_order_mutation import RoomOrderMutation
from .entrance_mutation import EntranceMutation
from .zone_priority_mutation import ZonePriorityMutation
from .packing_seed_mutation import PackingSeedMutation


class MutationManager:

    def __init__(self):

        self.room = RoomOrderMutation()

        self.entrance = EntranceMutation()

        self.zone = ZonePriorityMutation()

        self.packing = PackingSeedMutation()

    def mutate(

        self,

        index,

        rooms,

        plot,

        zones,

    ):

        cloned = copy.deepcopy(
            rooms
        )

        mutation = mutation_engine.choose()

        if mutation.value == "SWAP":

            return self.room.apply(
                cloned,
                plot,
                zones,
            )

        if mutation.value == "SHIFT":

            return self.entrance.apply(
                cloned,
                plot,
                zones,
            )

        if mutation.value == "ZONE":

            return self.zone.apply(
                cloned,
                plot,
                zones,
            )

        if mutation.value == "PACKING":

            return self.packing.apply(
                cloned,
                plot,
                zones,
            )

        return cloned