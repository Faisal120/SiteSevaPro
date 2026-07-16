"""
Optimization Stage
"""

from services.design_engine.optimizer.optimizer import (
    layout_optimizer,
)

from services.design_engine.solver.constraint_solver import (
    constraint_solver,
)

from services.design_engine.graph.graph_builder import (
    graph_builder,
)

from services.design_engine.graph.graph_validator import (
    graph_validator,
)


class OptimizationStage:

    def run(
        self,
        context,
    ):

        solution = layout_optimizer.optimize(

            context.rooms,

            graph_builder,

            graph_validator,

            constraint_solver,

            context.zones,

        )

        context.solution = solution

        context.score = solution.score

        context.rooms = solution.rooms

        return context


optimization_stage = OptimizationStage()