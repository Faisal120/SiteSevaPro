"""
Documentation Engine

Generates all architectural documents from the DesignContext.
"""

from services.design_engine.documentation.drawing_generator import (
    drawing_generator,
)

from services.design_engine.documentation.schedules.schedule_engine import (
    schedule_engine,
)

from services.design_engine.documentation.sheets.sheet_renderer import (
    sheet_renderer,
)

from services.design_engine.documentation.exporters import (
    export_engine,
)


class DocumentationEngine:

    def generate(
        self,
        context,
    ):
        """
        Generate all documentation for the current design.
        """

        # ----------------------------------------
        # Generate schedules
        # ----------------------------------------

        context.schedules = schedule_engine.generate(
            context
        )

        # ----------------------------------------
        # Generate drawing definitions
        # ----------------------------------------

        context.drawings = drawing_generator.generate(
            context
        )

        # ----------------------------------------
        # Compose final sheets
        # ----------------------------------------

        context.drawings = sheet_renderer.render(
            context,
            context.project,
        )
        
        context.exports = export_engine.export(
            context,
        )

        return context


documentation_engine = DocumentationEngine()