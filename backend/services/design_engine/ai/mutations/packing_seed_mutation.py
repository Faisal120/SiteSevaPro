import copy
import random

from .base_mutation import BaseMutation


class PackingSeedMutation(BaseMutation):

    def apply(

        self,

        rooms,

        plot,

        zones,

    ):

        cloned = copy.deepcopy(

            rooms

        )

        random.shuffle(

            cloned

        )

        return cloned