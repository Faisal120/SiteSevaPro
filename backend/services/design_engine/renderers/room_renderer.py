"""
Room Renderer
"""


ROOM_COLORS = {

    "Living": "#FFF7D6",

    "Kitchen": "#FFE4C4",

    "Bedroom": "#DDEBFF",

    "Master Bedroom": "#D6E9FF",

    "Bath": "#EFEFEF",

    "Toilet": "#EFEFEF",

    "Dining": "#FFF2CC",

    "Store": "#F8F8F8",

}


class RoomRenderer:

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

            color = ROOM_COLORS.get(
                room.name,
                "#F9FAFB",
            )

            context.elements.append(

                f"""
                <rect
                    x="{x}"
                    y="{y}"
                    width="{w}"
                    height="{h}"
                    fill="{color}"
                    stroke="#444"
                    stroke-width="2"
                />
                """

            )

        return context


room_renderer = RoomRenderer()