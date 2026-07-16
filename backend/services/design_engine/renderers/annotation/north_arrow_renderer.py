"""
North Arrow Renderer
"""


ROTATION = {

    "NORTH":0,

    "EAST":90,

    "SOUTH":180,

    "WEST":270,

}


class NorthArrowRenderer:

    def render(

        self,

        context,

        plot,

    ):

        angle = ROTATION.get(

            plot.facing.upper(),

            0,

        )

        cx = context.width - 70

        cy = 70

        context.elements.append(

            f"""
            <g transform="rotate({angle} {cx} {cy})">

            <line
                x1="{cx}"
                y1="{cy+20}"
                x2="{cx}"
                y2="{cy-20}"
                stroke="black"
                stroke-width="2"
            />

            <polygon
                points="{cx},{cy-28}
                {cx-6},{cy-16}
                {cx+6},{cy-16}"
                fill="black"
            />

            <text
                x="{cx}"
                y="{cy-35}"
                text-anchor="middle"
                font-size="14"
            >

            N

            </text>

            </g>

            """

        )

        return context


north_arrow_renderer = NorthArrowRenderer()