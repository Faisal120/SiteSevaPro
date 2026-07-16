"""
Architectural Wall Renderer
"""

WALL_THICKNESS = 8


class WallRenderer:

    def render(
        self,
        context,
        rooms,
    ):

        for room in rooms:

            x = context.margin + room.x * context.scale

            y = context.margin + room.y * context.scale

            w = room.width * context.scale

            h = room.length * context.scale

            # Outer Wall
            context.elements.append(
                f"""
                <rect
                    x="{x}"
                    y="{y}"
                    width="{w}"
                    height="{h}"
                    fill="none"
                    stroke="#111111"
                    stroke-width="{WALL_THICKNESS}"
                />
                """
            )

            # Inner Finish Line
            context.elements.append(
                f"""
                <rect
                    x="{x + WALL_THICKNESS/2}"
                    y="{y + WALL_THICKNESS/2}"
                    width="{w - WALL_THICKNESS}"
                    height="{h - WALL_THICKNESS}"
                    fill="none"
                    stroke="#999999"
                    stroke-width="1"
                />
                """
            )

        return context


wall_renderer = WallRenderer()