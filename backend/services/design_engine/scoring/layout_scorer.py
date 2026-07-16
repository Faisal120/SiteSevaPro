from services.design_engine.scoring.circulation_score import (
    circulation_score,
)

from services.design_engine.scoring.lighting_score import (
    lighting_score,
)

from services.design_engine.scoring.privacy_score import (
    privacy_score,
)

from services.design_engine.scoring.cost_score import (
    cost_score,
)

from services.design_engine.scoring.structure_score import (
    structure_score,
)

from services.design_engine.scoring.ventilation_score import (
    ventilation_score,
)

from services.design_engine.scoring.vastu_score import (
    vastu_score,
)

from services.design_engine.solver.solution import Solution


class LayoutScorer:

    def evaluate(

        self,

        rooms,

        graph,

        zones,

    ):

        total = 0

        total += circulation_score.score(

            graph

        )

        total += lighting_score.score(

            rooms

        )

        total += privacy_score.score(

            graph

        )

        total += cost_score.score(

            rooms

        )

        total += structure_score.score(

            rooms

        )

        total += ventilation_score.score(

            rooms

        )

        total += vastu_score.score(

            rooms,

            zones,

        )

        return Solution(

            score=total,

            rooms=rooms,

        )


layout_scorer = LayoutScorer()