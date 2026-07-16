"""
Background Renderer
"""


class BackgroundRenderer:

    def render(
        self,
        context,
    ):

        context.elements.append(

            f"""
            <rect
                x="0"
                y="0"
                width="{context.width}"
                height="{context.height}"
                fill="#ffffff"
            />
            """

        )

        return context


background_renderer = BackgroundRenderer()