"""
Graph Stage

Creates the layout graph.
"""

from services.design_engine.graph.graph_builder import (
    graph_builder,
)

from services.design_engine.graph.graph_validator import (
    graph_validator,
)

from services.design_engine.graph.graph_exporter import (
    graph_exporter,
)


class GraphStage:

    def run(self, context):

        context.graph = graph_builder.build(context.rooms)

        print("\n========== GRAPH DEBUG ==========")
        print("Rooms:", len(context.rooms))
        print("Nodes:", len(context.graph.all_nodes()))

        edge_count = sum(
            len(node.edges)
            for node in context.graph.all_nodes()
        )

        print("Edges:", edge_count)

        for node in context.graph.all_nodes():
            neighbours = context.graph.neighbours(node.id)
            print(
                f"{node.room_name} -> {[n.room_name for n in neighbours]}"
            )

        is_valid = graph_validator.validate(context.graph)

        print("Graph valid:", is_valid)
        print("=================================\n")

        if not is_valid:
            raise Exception("Invalid Layout Graph")

        context.graph_json = graph_exporter.export(context.graph)

        return context
    
graph_stage = GraphStage()