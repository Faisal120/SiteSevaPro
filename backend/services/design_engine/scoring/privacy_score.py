class PrivacyScore:

    def score(

        self,

        graph,

    ):

        score = 0

        for node in graph.all_nodes():

            if node.room_name == "Bedroom":

                for edge in node.edges:

                    neighbour = graph.get_node(

                        edge.target

                    )

                    if neighbour.room_name == "Living":

                        score -= 50

        return score


privacy_score = PrivacyScore()