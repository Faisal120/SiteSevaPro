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

    def run(
        self,
        context,
    ):

        context.graph = graph_builder.build(

            context.rooms

        )

        if not graph_validator.validate(

            context.graph

        ):

            raise Exception(

                "Invalid Layout Graph"

            )

        context.graph_json = graph_exporter.export(

            context.graph

        )

        return context


graph_stage = GraphStage()