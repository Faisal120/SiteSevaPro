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

        context.margin = 60

        context.width = int(

            plot.width * context.scale

            + context.margin * 2

        )

        context.height = int(

            plot.length * context.scale

            + context.margin * 2

        )

        return context


canvas = Canvas()