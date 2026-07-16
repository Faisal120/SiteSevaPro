from services.design_engine.documentation.sheet import DrawingSheet

from services.design_engine.documentation.drawing_number import (

    drawing_number,

)


class DrawingGenerator:

    def generate(

        self,

        design,

    ):

        sheet = DrawingSheet(

            number=drawing_number.generate(

                "SSP",

                101,

            ),

            title="Floor Plan",

            scale="1:100",

            size="A3",

        )

        sheet.svg = design["svg"]

        return [

            sheet

        ]


drawing_generator = DrawingGenerator()