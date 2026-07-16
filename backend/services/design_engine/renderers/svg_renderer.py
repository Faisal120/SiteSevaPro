from services.design_engine.renderers.canvas import (
    canvas,
)

from services.design_engine.renderers.svg_document import (
    svg_document,
)

from services.design_engine.renderers.background_renderer import (
    background_renderer,
)

from services.design_engine.renderers.plot_renderer import (
    plot_renderer,
)

from services.design_engine.renderers.room_renderer import (
    room_renderer,
)

from services.design_engine.renderers.label_renderer import (
    label_renderer,
)
from services.design_engine.renderers.wall_renderer import (
    wall_renderer,
)

from services.design_engine.renderers.window_symbol_renderer import (
    window_symbol_renderer,
)

from services.design_engine.renderers.door_symbol_renderer import (
    door_symbol_renderer,
)


from services.design_engine.renderers.annotation.dimension_renderer import (
    dimension_renderer,
)
from services.design_engine.renderers.annotation.north_arrow_renderer import (
    north_arrow_renderer,
)

from services.design_engine.renderers.annotation.scale_renderer import (
    scale_renderer,
)

from services.design_engine.renderers.annotation.title_block_renderer import (
    title_block_renderer,
)


class SVGRenderer:

    def render(
        self,
        layout,
    ):

        context = canvas.build(
            layout["plot"]
        )

        background_renderer.render(
            context
        )

        plot_renderer.render(
            context,
            layout["plot"],
        )

        room_renderer.render(
            context,
            layout["rooms"],
        )
        
        wall_renderer.render(
            context,
            layout["rooms"],
        )

        door_symbol_renderer.render(
            context,
            layout["doors"],
        )

        window_symbol_renderer.render(
            context,
            layout["windows"],
        )

        label_renderer.render(
            context,
            layout["rooms"],
        )
        
        dimension_renderer.render(

            context,

            layout["plot"],

        )

        north_arrow_renderer.render(

            context,

            layout["plot"],

        )

        scale_renderer.render(

            context,

        )

        title_block_renderer.render(

            context,

            layout,

        )

        return svg_document.render(
            context
        )


svg_renderer = SVGRenderer()