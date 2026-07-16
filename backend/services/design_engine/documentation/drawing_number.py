from datetime import datetime


class DrawingNumber:

    def generate(

        self,

        prefix,

        number,

    ):

        year = datetime.now().year

        return f"{prefix}-{year}-{number:03d}"


drawing_number = DrawingNumber()