"""
Constraint Solver

Evaluates layouts.
"""

from services.design_engine.solver.solution import Solution

from services.design_engine.solver.room_score import room_score

from services.design_engine.solver.zone_score import zone_score

from services.design_engine.solver.adjacency_score import adjacency_score


class ConstraintSolver:

    def evaluate(

        self,

        rooms,

        graph,

        zones,

    ):

        total = 0

        for room in rooms:

            total += room_score.score(

                room,

            )

            total += zone_score.score(

                room,

                zones,

            )

            total += adjacency_score.score(

                room,

                graph,

            )

        return Solution(

            score=total,

            rooms=rooms,

        )


constraint_solver = ConstraintSolver()