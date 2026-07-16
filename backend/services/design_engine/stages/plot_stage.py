"""
Plot Stage
"""

from services.design_engine.types import Plot


class PlotStage:

    def run(
        self,
        context,
    ):

        body = context.body

        context.plot = Plot(

            width=body.plot_width,

            length=body.plot_length,

            facing=body.facing,

        )

        return context


plot_stage = PlotStage()