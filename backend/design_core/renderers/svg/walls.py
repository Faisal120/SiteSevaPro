from .theme import THEME


def draw_wall(svg, x, y, w, h):

    svg.append(f"""
    <rect
        x="{x}"
        y="{y}"
        width="{w}"
        height="{h}"
        fill="{THEME.room_fill}"
        stroke="{THEME.wall}"
        stroke-width="8"
    />
    """)

    svg.append(f"""
    <rect
        x="{x+4}"
        y="{y+4}"
        width="{w-8}"
        height="{h-8}"
        fill="none"
        stroke="{THEME.wall_shadow}"
        stroke-width="1"
    />
    """)