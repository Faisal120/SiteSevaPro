class EliteManager:

    KEEP = 10

    def preserve(

        self,

        population,

    ):

        population.sort(

            key=lambda x: x.score,

            reverse=True,

        )

        return population[: self.KEEP]


elite_manager = EliteManager()