import copy

from .base_mutation import BaseMutation


class ZonePriorityMutation(BaseMutation):

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

            if room.name == "Kitchen":

                room.preferred_zone = "NORTH_EAST"

        return cloned