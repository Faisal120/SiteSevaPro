"""
Draws ISO drawing border.
"""


class BorderRenderer:

    MARGIN = 20

    def render(
        self,
        context,
    ):

        context.elements.append(

            f"""
            <rect
                x="{self.MARGIN}"
                y="{self.MARGIN}"
                width="{context.width-self.MARGIN*2}"
                height="{context.height-self.MARGIN*2}"
                fill="none"
                stroke="#000"
                stroke-width="2"
            />
            """

        )

        return context


border_renderer = BorderRenderer()