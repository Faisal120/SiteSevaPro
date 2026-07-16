"""
Overlap Stage
"""

from services.design_engine.overlap_resolver import (
    overlap_resolver,
)


class OverlapStage:

    def run(
        self,
        context,
    ):

        context.rooms = overlap_resolver.resolve(

            context.rooms,

        )

        return context


overlap_stage = OverlapStage()