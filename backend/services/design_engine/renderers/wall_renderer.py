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

        # Draw each physical boundary once.  Rendering a complete rectangle
        # for every room created double-thick shared walls in the old output.
        walls = {}
        for room in rooms:
            x1 = context.margin + room.x * context.scale
            y1 = context.margin + room.y * context.scale
            x2 = x1 + room.width * context.scale
            y2 = y1 + room.length * context.scale
            for start, end in (((x1, y1), (x2, y1)), ((x2, y1), (x2, y2)),
                               ((x1, y2), (x2, y2)), ((x1, y1), (x1, y2))):
                key = tuple(sorted((
                    (round(start[0], 3), round(start[1], 3)),
                    (round(end[0], 3), round(end[1], 3)),
                )))
                walls[key] = (start, end)

        for start, end in walls.values():
            context.elements.append(
                f'<line x1="{start[0]}" y1="{start[1]}" '
                f'x2="{end[0]}" y2="{end[1]}" stroke="#202124" '
                f'stroke-width="{WALL_THICKNESS}" stroke-linecap="square" />'
            )

        return context


wall_renderer = WallRenderer()
