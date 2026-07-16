class WalkingPath:

    def validate(
        self,
        room,
        furniture,
    ):

        free_area = (

            room.width * room.length

        )

        occupied = 0

        for item in furniture:

            occupied += (

                item.width *

                item.length

            )

        ratio = occupied / free_area

        return ratio < 0.60


walking_path = WalkingPath()