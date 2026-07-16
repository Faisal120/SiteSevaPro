from services.design_engine.ai import (

    candidate_generator,

    candidate_manager,

)


class CandidateStage:

    def run(

        self,

        context,

    ):

        layouts = candidate_generator.generate(

            context.rooms,

            context.plot,

            context.zones,

            count=5,

        )

        context.candidates = candidate_manager.build(

            layouts

        )

        context.selected_candidate = (

            context.candidates[0]

        )

        context.rooms = (

            context.selected_candidate.rooms

        )

        return context


candidate_stage = CandidateStage()