def bed(x, y):

    return f"""
    <rect x="{x}" y="{y}" width="80" height="120"
          fill="none" stroke="black" stroke-width="2"/>

    <rect x="{x+10}" y="{y+10}" width="60" height="25"
          fill="none" stroke="black"/>

    <rect x="{x+10}" y="{y+45}" width="60" height="60"
          fill="none" stroke="black"/>
    """


def sofa(x, y):

    return f"""
    <rect x="{x}" y="{y}" width="100" height="50"
          fill="none" stroke="black"/>

    <rect x="{x}" y="{y}" width="15" height="50"
          fill="none" stroke="black"/>

    <rect x="{x+85}" y="{y}" width="15" height="50"
          fill="none" stroke="black"/>
    """


def toilet(x, y):

    return f"""
    <ellipse cx="{x}" cy="{y}" rx="18" ry="25"
             fill="none" stroke="black"/>

    <rect x="{x-12}" y="{y-40}"
          width="24"
          height="18"
          fill="none"
          stroke="black"/>
    """


def basin(x, y):

    return f"""
    <circle cx="{x}" cy="{y}" r="12"
            fill="none"
            stroke="black"/>
    """


def car(x, y):

    return f"""
    <rect
        x="{x}"
        y="{y}"
        width="90"
        height="170"
        rx="20"
        fill="none"
        stroke="black"/>

    <line
        x1="{x+15}"
        y1="{y+30}"
        x2="{x+75}"
        y2="{y+30}"
        stroke="black"/>

    <line
        x1="{x+15}"
        y1="{y+140}"
        x2="{x+75}"
        y2="{y+140}"
        stroke="black"/>
    """
    
def stairs(x, y):

    svg = ""

    for i in range(10):

        svg += f"""
        <line
            x1="{x}"
            y1="{y + i*12}"
            x2="{x+100}"
            y2="{y + i*12}"
            stroke="black"
            stroke-width="1"
        />
        """

    return svg    