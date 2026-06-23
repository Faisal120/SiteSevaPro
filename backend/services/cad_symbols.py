def door(x, y):

    return f"""
    <path
        d="M{x} {y}
           L{x+40} {y}
           A40 40 0 0 1 {x} {y+40}"
        stroke="black"
        stroke-width="2"
        fill="none"
    />
    """


def window(x, y, width=60):

    return f"""
    <line
        x1="{x}"
        y1="{y}"
        x2="{x+width}"
        y2="{y}"
        stroke="#2196f3"
        stroke-width="4"
    />
    """


def bed(x,y):

    return f"""
    <rect
        x="{x}"
        y="{y}"
        width="80"
        height="120"
        fill="none"
        stroke="gray"
    />

    <rect
        x="{x+5}"
        y="{y+5}"
        width="30"
        height="20"
        fill="none"
        stroke="gray"
    />

    <rect
        x="{x+45}"
        y="{y+5}"
        width="30"
        height="20"
        fill="none"
        stroke="gray"
    />
    """


def sofa(x,y):

    return f"""
    <rect
        x="{x}"
        y="{y}"
        width="100"
        height="40"
        fill="none"
        stroke="gray"
    />
    """