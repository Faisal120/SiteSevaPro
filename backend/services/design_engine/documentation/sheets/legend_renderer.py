class LegendRenderer:

    SYMBOLS = [

        ("D","Door"),

        ("W","Window"),

        ("█","Wall"),

        ("C","Column"),

        ("S","Stair"),

    ]

    def render(

        self,

        sheet,

    ):

        sheet.legends = self.SYMBOLS

        return sheet


legend_renderer = LegendRenderer()