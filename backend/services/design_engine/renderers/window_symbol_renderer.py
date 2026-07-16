"""
Window Symbol Renderer
"""


class WindowSymbolRenderer:

    def render(
        self,
        context,
        windows,
    ):

        for window in windows:

            x = context.margin + window["x"] * context.scale

            y = context.margin + window["y"] * context.scale

            length = window.get("width", 1.2) * context.scale

            context.elements.append(
                f"""
                <line
                    x1="{x}"
                    y1="{y}"
                    x2="{x+length}"
                    y2="{y}"
                    stroke="#0077ff"
                    stroke-width="4"
                />
                """
            )

        return context


window_symbol_renderer = WindowSymbolRenderer()