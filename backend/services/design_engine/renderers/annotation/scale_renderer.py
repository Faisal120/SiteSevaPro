"""
Scale Bar Renderer
"""


class ScaleRenderer:

    def render(

        self,

        context,

    ):

        x = context.margin

        y = context.height - 35

        context.elements.append(

            f"""
            <text
                x="{x}"
                y="{y}"
                font-size="12"
            >

            Scale : 1 : 100

            </text>

            """

        )

        return context


scale_renderer = ScaleRenderer()