"""
Graph Export

Useful for debugging.
"""


class GraphExporter:

    def export(

        self,

        graph,

    ):

        result = []

        for node in graph.all_nodes():

            result.append(

                {

                    "id": node.id,

                    "room": node.room_name,

                    "zone": node.zone,

                    "edges": [

                        {

                            "to": edge.target,

                            "type": edge.edge_type,

                        }

                        for edge in node.edges

                    ],

                }

            )

        return result


graph_exporter = GraphExporter()