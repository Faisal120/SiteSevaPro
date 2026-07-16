from datetime import datetime


class TitleBlockRenderer:

    def render(

        self,

        context,

        layout,

    ):

        x = context.width - 280

        y = context.height - 140

        context.elements.append(

            f"""
            <rect
                x="{x}"
                y="{y}"
                width="260"
                height="120"
                fill="white"
                stroke="#000"
            />
            """

        )

        rows = [

            "SITESEVA PRO",

            f"Plot : {layout['plot'].width} x {layout['plot'].length}",

            f"Facing : {layout['plot'].facing}",

            f"Rooms : {len(layout['rooms'])}",

            f"Generated : {datetime.now().strftime('%d-%m-%Y')}",

        ]

        yy = y + 20

        for row in rows:

            context.elements.append(

                f"""
                <text
                    x="{x+10}"
                    y="{yy}"
                    font-size="11"
                >

                {row}

                </text>

                """

            )

            yy += 20

        return context


title_block_renderer = TitleBlockRenderer()