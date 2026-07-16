from .schedule_base import Schedule


class DoorSchedule:

    def generate(
        self,
        context,
    ):

        schedule = Schedule(

            title="Door Schedule",

            columns=[

                "ID",

                "Width",

                "Height",

                "Room",

            ],

        )

        for i, door in enumerate(context.doors):

            schedule.add_row(

                ID=f"D{i+1}",

                Width=door.width,

                Height=door.height,

                Room=door.room,

            )

        return schedule


door_schedule = DoorSchedule()