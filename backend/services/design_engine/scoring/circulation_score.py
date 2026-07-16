class CirculationScore:

    def score(

        self,

        graph,

    ):

        score = 0

        for node in graph.all_nodes():

            degree = len(node.edges)

            if degree >= 2:

                score += 25

            elif degree == 1:

                score += 10

            else:

                score -= 100

        return score


circulation_score = CirculationScore()