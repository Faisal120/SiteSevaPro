from .walls import draw_wall
from .typography import room_label
from .typography import room_area


def draw_room(svg, room, canvas):

    x = room.x * canvas.scale + canvas.offset_x

    y = room.y * canvas.scale + canvas.offset_y

    w = room.width * canvas.scale

    h = room.height * canvas.scale

    draw_wall(svg, x, y, w, h)

    room_label(
        svg,
        x + w / 2,
        y + h / 2 - 10,
        room.name.replace("_", " "),
    )

    room_area(
        svg,
        x + w / 2,
        y + h / 2 + 15,
        room.width * room.height,
    )