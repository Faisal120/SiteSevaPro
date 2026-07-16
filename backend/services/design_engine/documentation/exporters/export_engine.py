from services.design_engine.documentation.exporters.pdf_exporter import (
    pdf_exporter,
)

from services.design_engine.documentation.exporters.svg_exporter import (
    svg_exporter,
)

from services.design_engine.documentation.exporters.png_exporter import (
    png_exporter,
)

from services.design_engine.documentation.exporters.zip_exporter import (
    zip_exporter,
)


class ExportEngine:

    def export(
        self,
        context,
    ):

        exports = {}

        exports["svg"] = svg_exporter.export(
            context,
        )

        exports["pdf"] = pdf_exporter.export(
            context,
        )

        exports["png"] = png_exporter.export(
            context,
        )

        exports["zip"] = zip_exporter.export(
            context,
            exports,
        )

        return exports


export_engine = ExportEngine()