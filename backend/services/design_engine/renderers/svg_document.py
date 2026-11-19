class SVGDocument:

    def render(

        self,

        context,

    ):

        svg = [

            f'<svg xmlns="http://www.w3.org/2000/svg" '
            f'viewBox="0 0 {context.width} {context.height}" '
            f'preserveAspectRatio="xMidYMid meet">'

        ]

        svg.extend(

            context.defs

        )

        svg.extend(

            context.elements

        )

        svg.append(

            "</svg>"

        )

        return "\n".join(svg)


svg_document = SVGDocument()
