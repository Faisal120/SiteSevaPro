class Fitness:

    def evaluate(

        self,

        candidates,

    ):

        candidates.sort(

            key=lambda x: x.score,

            reverse=True,

        )

        return candidates


fitness = Fitness()