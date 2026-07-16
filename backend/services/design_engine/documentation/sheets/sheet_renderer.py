from services.design_engine.documentation.sheets.sheet_composer import (
    sheet_composer,
)


class SheetRenderer:

    def render(

        self,

        context,

        project,

    ):

        sheets = []

        for sheet in context.drawings:

            sheets.append(

                sheet_composer.compose(

                    sheet,

                    context,

                    project,

                )

            )

        return sheets


sheet_renderer = SheetRenderer()