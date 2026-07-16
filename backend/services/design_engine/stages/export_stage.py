"""
Export Stage

Creates the final API response.
"""

from services.design_engine.renderers.json_renderer import (
    json_renderer,
)


class ExportStage:

    def run(
        self,
        context,
    ):

        context.response = json_renderer.render(
            context
        )

        return context


export_stage = ExportStage()