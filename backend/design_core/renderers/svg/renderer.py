from .canvas import Canvas

from .rooms import draw_room

from .titleblock import draw_titleblock

from .north import draw_north


class SVGRenderer:

    def render(self, layout):

        canvas = Canvas()

        canvas.fit(

            layout.plot.width,

            layout.plot.length,

        )

        svg = [

            f"""
            <svg
                xmlns="http://www.w3.org/2000/svg"
                width="{canvas.width}"
                height="{canvas.height}"
                viewBox="0 0 {canvas.width} {canvas.height}">
            """
        ]

        for room in layout.rooms:

            draw_room(
                svg,
                room,
                canvas,
            )

        draw_north(svg, canvas)

        draw_titleblock(svg, layout, canvas)

        svg.append("</svg>")

        return "".join(svg)