from services.design_engine.renderers.render_context import (
    RenderContext,
)


class Canvas:

    def build(

        self,

        plot,

    ):

        context = RenderContext()

        context.scale = 25

        # Leave room for external dimensions and a drawing title block.
        context.margin = 80

        context.width = int(

            plot.width * context.scale

            + context.margin * 2

        )

        context.height = int(

            plot.length * context.scale

            + context.margin + 150

        )

        return context


canvas = Canvas()
