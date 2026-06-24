def draw_wall(x, y, w, h):

    return f"""
    <rect
        x="{x}"
        y="{y}"
        width="{w}"
        height="{h}"
        fill="white"
        stroke="black"
        stroke-width="9"
    />
    """


def draw_door(x, y):

    return f"""
    <path
        d="M{x} {y}
           A40 40 0 0 0 {x+40} {y-40}"
        fill="none"
        stroke="black"
        stroke-width="2"/>

    <line
        x1="{x}"
        y1="{y}"
        x2="{x+40}"
        y2="{y}"
        stroke="black"
        stroke-width="2"/>
    """


def draw_window(x, y):

    return f"""
    <line
        x1="{x}"
        y1="{y}"
        x2="{x+60}"
        y2="{y}"
        stroke="#2563eb"
        stroke-width="4"/>
    """