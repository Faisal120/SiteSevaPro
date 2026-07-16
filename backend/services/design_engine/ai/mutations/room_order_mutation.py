import copy

from .base_mutation import BaseMutation


class RoomOrderMutation(BaseMutation):

    def apply(

        self,

        rooms,

        plot,

        zones,

    ):

        cloned = copy.deepcopy(

            rooms

        )

        cloned.sort(

            key=lambda r: r.area,

            reverse=True,

        )

        return cloned