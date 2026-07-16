from services.design_engine.ai.layout_candidate import (
    LayoutCandidate,
)


class CandidateManager:

    def build(

        self,

        layouts,

    ):

        candidates = []

        for index, layout in enumerate(layouts):

            candidates.append(

                LayoutCandidate(

                    id=index + 1,

                    rooms=layout,

                )

            )

        return candidates


candidate_manager = CandidateManager()