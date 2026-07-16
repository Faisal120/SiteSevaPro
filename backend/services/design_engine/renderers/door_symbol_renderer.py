"""
Door Symbol Renderer
"""

import math


class DoorSymbolRenderer:

    DOOR_WIDTH = 30

    def render(
        self,
        context,
        doors,
    ):

        for door in doors:

            x = context.margin + door["x"] * context.scale

            y = context.margin + door["y"] * context.scale

            r = self.DOOR_WIDTH

            context.elements.append(
                f"""
                <line
                    x1="{x}"
                    y1="{y}"
                    x2="{x+r}"
                    y2="{y}"
                    stroke="black"
                    stroke-width="2"
                />
                """
            )

            context.elements.append(
                f"""
                <path
                    d="M {x} {y}
                    A {r} {r}
                    0 0 1
                    {x+r} {y+r}"
                    fill="none"
                    stroke="#666"
                    stroke-width="1"
                />
                """
            )

        return context


door_symbol_renderer = DoorSymbolRenderer()