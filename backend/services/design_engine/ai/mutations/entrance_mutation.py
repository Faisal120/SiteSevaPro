import copy

from .base_mutation import BaseMutation


class EntranceMutation(BaseMutation):

    def apply(

        self,

        rooms,

        plot,

        zones,

    ):

        cloned = copy.deepcopy(

            rooms

        )

        for room in cloned:

            if room.name == "Living":

                room.preferred_zone = "FRONT"

                break

        return cloned