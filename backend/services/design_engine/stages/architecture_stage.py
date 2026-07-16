"""
Architecture Stage
"""

from services.design_engine.corridor_engine import (
    corridor_engine,
)

from services.design_engine.door_engine import (
    door_engine,
)

from services.design_engine.window_engine import (
    window_engine,
)

from services.design_engine.graph.graph_builder import (
    graph_builder,
)

from services.design_engine.graph.graph_exporter import (
    graph_exporter,
)


class ArchitectureStage:

    def run(
        self,
        context,
    ):

        context.graph = graph_builder.build(

            context.rooms

        )

        context.graph_json = graph_exporter.export(

            context.graph

        )

        context.corridors = corridor_engine.generate(

            context.rooms

        )

        context.doors = door_engine.generate(

            context.rooms

        )

        context.windows = window_engine.generate(

            context.rooms,

            context.plot,

        )

        return context


architecture_stage = ArchitectureStage()