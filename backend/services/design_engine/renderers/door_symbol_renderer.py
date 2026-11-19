class DoorSymbolRenderer:

    WALL_GAP = 10

    def render(
        self,
        context,
        doors,
    ):

        for door in doors:

            # Support both dataclass objects and dicts
            if isinstance(door, dict):
                door_x = door.get("x", 0)
                door_y = door.get("y", 0)
                width = door.get("width", 3)
                wall = door.get("wall", "north")
            else:
                door_x = getattr(door, "x", 0)
                door_y = getattr(door, "y", 0)
                width = getattr(door, "width", 3)
                wall = getattr(door, "wall", "north")

            x = context.margin + door_x * context.scale
            y = context.margin + door_y * context.scale

            r = width * context.scale
            wall = wall.upper()
            vertical = wall in {"EAST", "WEST"}

            # Cut an opening through the wall before drawing the door leaf.
            if vertical:
                gap = f'<line x1="{x}" y1="{y-r / 2}" x2="{x}" y2="{y+r / 2}" stroke="white" stroke-width="{self.WALL_GAP}" />'
                x1, y1, x2, y2 = x, y-r/2, x, y+r/2
                arc_end_x = x + (r if wall == "EAST" else -r)
                arc_end_y = y-r/2
            else:
                gap = f'<line x1="{x-r / 2}" y1="{y}" x2="{x+r / 2}" y2="{y}" stroke="white" stroke-width="{self.WALL_GAP}" />'
                x1, y1, x2, y2 = x-r/2, y, x+r/2, y
                arc_end_x = x-r/2
                arc_end_y = y + (r if wall == "SOUTH" else -r)

            context.elements.append(gap)

            context.elements.append(
                f"""
                <line
                    x1="{x1}"
                    y1="{y1}"
                    x2="{x2}"
                    y2="{y2}"
                    stroke="black"
                    stroke-width="2"
                />
                """
            )

            context.elements.append(
                f"""
                <path
                    d="M {x1} {y1}
                    A {r} {r}
                    0 0 1
                    {arc_end_x} {arc_end_y}"
                    fill="none"
                    stroke="#666"
                    stroke-width="1"
                />
                """
            )

        return context


door_symbol_renderer = DoorSymbolRenderer()
