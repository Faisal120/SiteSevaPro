"""
Geometry Stage
"""

from services.design_engine.geometry_engine import (
    geometry_engine,
)


class GeometryStage:

    def run(
        self,
        context,
    ):

        context.rooms = geometry_engine.place(

            context.rooms,

            context.plot,

            context.zones,

        )

        return context


geometry_stage = GeometryStage()