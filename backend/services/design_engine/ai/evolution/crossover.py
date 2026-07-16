import copy
import random


class Crossover:

    def cross(

        self,

        parent_a,

        parent_b,

    ):

        child = copy.deepcopy(

            parent_a

        )

        split = len(

            child.rooms

        ) // 2

        child.rooms[split:] = copy.deepcopy(

            parent_b.rooms[split:]

        )

        child.score = 0

        return child


crossover = Crossover()