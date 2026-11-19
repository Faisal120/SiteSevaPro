from dataclasses import dataclass


@dataclass
class SvgTheme:

    canvas = "#FFFFFF"

    room_fill = "#FFFFFF"

    wet_room_fill = "#F5F5F5"

    wall = "#111111"

    wall_shadow = "#777777"

    dimension = "#444444"

    label = "#111111"

    secondary = "#666666"

    title = "#111111"

    border = "#222222"

    font = "Inter, Arial, sans-serif"


THEME = SvgTheme()