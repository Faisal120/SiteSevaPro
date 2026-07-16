from services.design_engine.documentation.sheets.viewport_renderer import (
    viewport_renderer,
)

from services.design_engine.documentation.sheets.title_block_renderer import (
    title_block_renderer,
)

from services.design_engine.documentation.sheets.legend_renderer import (
    legend_renderer,
)

from services.design_engine.documentation.sheets.revision_table import (
    revision_table,
)


class SheetComposer:

    def compose(

        self,

        sheet,

        context,

        project,

    ):

        viewport_renderer.render(

            sheet,

            context.svg,

        )

        title_block_renderer.render(

            sheet,

            project,

        )

        legend_renderer.render(

            sheet,

        )

        sheet.revisions = revision_table.create()

        return sheet


sheet_composer = SheetComposer()