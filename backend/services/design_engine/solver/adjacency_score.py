"""
Adjacency Score
"""

class AdjacencyScore:

    def score(

        self,

        room,

        graph,

    ):

        node = graph.get_node(

            room.graph_id,

        )

        if node is None:

            return 0

        return len(node.edges) * 40


adjacency_score = AdjacencyScore()