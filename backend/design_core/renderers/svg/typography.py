from .theme import THEME


def room_label(svg, x, y, room):

    svg.append(f"""
        <text
            x="{x}"
            y="{y}"
            text-anchor="middle"
            font-size="20"
            font-weight="700"
            fill="{THEME.label}"
            font-family="{THEME.font}">
            {room.upper()}
        </text>
    """)
    
    
def room_area(svg, x, y, area):

    svg.append(f"""
        <text
            x="{x}"
            y="{y}"
            text-anchor="middle"
            font-size="13"
            fill="{THEME.secondary}"
            font-family="{THEME.font}">
            {area:.0f} sq.ft
        </text>
    """)