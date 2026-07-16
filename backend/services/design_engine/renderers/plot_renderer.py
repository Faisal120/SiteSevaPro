"""
Plot Boundary Renderer
"""


class PlotRenderer:

    def render(
        self,
        context,
        plot,
    ):

        x = context.margin
        y = context.margin

        w = plot.width * context.scale
        h = plot.length * context.scale

        context.elements.append(

            f"""
            <rect
                x="{x}"
                y="{y}"
                width="{w}"
                height="{h}"
                fill="none"
                stroke="#111827"
                stroke-width="3"
            />
            """

        )

        return context


plot_renderer = PlotRenderer()