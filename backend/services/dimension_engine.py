def horizontal_dimension(
    x,
    y,
    length,
    text
):

    return f"""
    <line
        x1="{x}"
        y1="{y}"
        x2="{x+length}"
        y2="{y}"
        stroke="black"
        stroke-width="2"
    />

    <line
        x1="{x}"
        y1="{y-10}"
        x2="{x}"
        y2="{y+10}"
        stroke="black"
    />

    <line
        x1="{x+length}"
        y1="{y-10}"
        x2="{x+length}"
        y2="{y+10}"
        stroke="black"
    />

    <text
        x="{x+length/2-40}"
        y="{y-15}"
        font-size="18">
        {text}
    </text>
    """
    
def vertical_dimension(
    x,
    y,
    height,
    text
):

    return f"""
    <line
        x1="{x}"
        y1="{y}"
        x2="{x}"
        y2="{y+height}"
        stroke="black"
        stroke-width="2"
    />

    <text
        x="{x-40}"
        y="{y+height/2}"
        transform="
        rotate(
            -90
            {x-40}
            {y+height/2}
        )"
        font-size="18">
        {text}
    </text>
    """