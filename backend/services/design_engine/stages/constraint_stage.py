"""
Constraint Stage

Creates rooms,
zones,
adjacency.
"""

from services.design_engine.zone_engine import (
    zone_engine,
)

from services.design_engine.constraint_engine import (
    constraint_engine,
)

from services.design_engine.adjacency_solver import (
    adjacency_solver,
)


class ConstraintStage:

    def run(
        self,
        context,
    ):

        context.zones = zone_engine.build(

            context.plot

        )

        context.rooms = constraint_engine.build_rooms(

            context.body

        )

        context.rooms = adjacency_solver.solve(

            context.rooms

        )

        return context


constraint_stage = ConstraintStage()