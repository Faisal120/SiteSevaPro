"""
Window Symbol Renderer
"""


class WindowSymbolRenderer:

    DEFAULT_WIDTH = 1.2

    def render(
        self,
        context,
        windows,
    ):

        for window in windows:

            if isinstance(window, dict):

                x = window.get("x", 0)
                y = window.get("y", 0)
                width = window.get(
                    "width",
                    self.DEFAULT_WIDTH,
                )
                wall = window.get("wall", "north")

            else:

                x = getattr(window, "x", 0)
                y = getattr(window, "y", 0)
                width = getattr(
                    window,
                    "width",
                    self.DEFAULT_WIDTH,
                )
                wall = getattr(window, "wall", "north")

            x = context.margin + x * context.scale
            y = context.margin + y * context.scale
            length = width * context.scale

            wall = wall.upper()
            if wall in {"EAST", "WEST"}:
                x1, y1, x2, y2 = x, y - length / 2, x, y + length / 2
            else:
                x1, y1, x2, y2 = x - length / 2, y, x + length / 2, y

            context.elements.append(
                f'<line x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}" stroke="white" stroke-width="10" />'
            )
            context.elements.append(
                f'<line x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}" stroke="#4b5563" stroke-width="3" />'
            )

        return context


window_symbol_renderer = WindowSymbolRenderer()
