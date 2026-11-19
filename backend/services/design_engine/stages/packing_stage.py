"""
Packing Stage
"""

from services.design_engine.packing.packing_solver import (
    packing_solver,
)


class PackingStage:

    def run(
        self,
        context,
    ):

        packed = packing_solver.solve(

            context.rooms,

            context.plot,

            variation=getattr(context.body, "variation", 0),

        )

        for room in packed:

            room.room.x = room.x
            room.room.y = room.y
            room.room.width = room.width
            room.room.length = room.height

        context.rooms = [

            room.room

            for room in packed

        ]

        return context


packing_stage = PackingStage()
