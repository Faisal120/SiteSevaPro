
class LayoutValidator:

    def validate(

        self,

        rooms,

        plot,

    ):

        for room in rooms:

            if (

                room.x + room.width

                > plot.width

            ):

                return False

            if (

                room.y + room.length

                > plot.length

            ):

                return False

        return True


layout_validator = LayoutValidator()