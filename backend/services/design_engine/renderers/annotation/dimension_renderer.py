"""
Architectural Dimension Renderer
"""


class DimensionRenderer:

    OFFSET = 25

    def render(

        self,

        context,

        plot,

    ):

        x = context.margin

        y = context.margin

        w = plot.width * context.scale

        h = plot.length * context.scale

        # Horizontal Dimension

        context.elements.append(

            f"""
            <line
                x1="{x}"
                y1="{y-self.OFFSET}"
                x2="{x+w}"
                y2="{y-self.OFFSET}"
                stroke="#222"
            />
            """

        )

        context.elements.append(

            f"""
            <text
                x="{x+w/2}"
                y="{y-self.OFFSET-5}"
                text-anchor="middle"
                font-size="12"
            >

            {plot.width:.2f} ft

            </text>
            """

        )

        # Vertical Dimension

        context.elements.append(

            f"""
            <line
                x1="{x-self.OFFSET}"
                y1="{y}"
                x2="{x-self.OFFSET}"
                y2="{y+h}"
                stroke="#222"
            />
            """

        )

        context.elements.append(

            f"""
            <text
                x="{x-self.OFFSET-10}"
                y="{y+h/2}"
                transform="rotate(-90 {x-self.OFFSET-10} {y+h/2})"
                font-size="12"
                text-anchor="middle"
            >

            {plot.length:.2f} ft

            </text>
            """

        )

        return context


dimension_renderer = DimensionRenderer()