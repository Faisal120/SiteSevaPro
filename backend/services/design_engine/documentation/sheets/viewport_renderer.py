class ViewportRenderer:

    def render(

        self,

        sheet,

        svg,

    ):

        sheet.svg = svg

        return sheet


viewport_renderer = ViewportRenderer()