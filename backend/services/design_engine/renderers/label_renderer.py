"""
Room Label Renderer
"""


class LabelRenderer:

    def render(
        self,
        context,
        rooms,
    ):

        for room in rooms:

            cx = context.margin + (room.x + room.width / 2) * context.scale

            cy = context.margin + (room.y + room.length / 2) * context.scale

            area = round(
                room.width * room.length,
                1,
            )

            context.elements.append(

                f"""
                <text
                    x="{cx}"
                    y="{cy}"
                    text-anchor="middle"
                    dominant-baseline="middle"
                    font-size="14"
                    font-family="Inter"
                    font-weight="600"
                >
                    {room.name}
                </text>
                """

            )

            context.elements.append(

                f"""
                <text
                    x="{cx}"
                    y="{cy + 18}"
                    text-anchor="middle"
                    font-size="11"
                    fill="#555"
                >
                    {area} sq.ft
                </text>
                """

            )

        return context


label_renderer = LabelRenderer()