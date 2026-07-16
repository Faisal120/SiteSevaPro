import copy
import random

from .base_mutation import BaseMutation


class ShiftMutation(BaseMutation):

    def apply(

        self,

        rooms,

        plot,

        zones,

    ):

        cloned = copy.deepcopy(
            rooms
        )

        room = random.choice(
            cloned
        )

        room.x += random.uniform(-1.5, 1.5)

        room.y += random.uniform(-1.5, 1.5)

        return cloned