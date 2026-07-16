"""
Simulated Annealing
"""

import math
import random


class Annealing:

    def accept(

        self,

        current,

        candidate,

        temperature,

    ):

        if candidate > current:

            return True

        probability = math.exp(

            (candidate - current) / temperature

        )

        return probability > random.random()


annealing = Annealing()