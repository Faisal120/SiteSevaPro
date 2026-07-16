import random


class TournamentSelection:

    SIZE = 5

    def select(

        self,

        population,

    ):

        tournament = random.sample(

            population,

            self.SIZE,

        )

        tournament.sort(

            key=lambda x: x.score,

            reverse=True,

        )

        return tournament[0]


selection = TournamentSelection()