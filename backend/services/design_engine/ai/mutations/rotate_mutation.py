import copy
import random

from .base_mutation import BaseMutation


class RotateMutation(BaseMutation):

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

        room.width, room.length = (

            room.length,

            room.width,

        )

        return cloned