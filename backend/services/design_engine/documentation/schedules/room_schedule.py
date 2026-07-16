from .schedule_base import Schedule


class RoomSchedule:

    def generate(
        self,
        context,
    ):

        schedule = Schedule(

            title="Room Schedule",

            columns=[

                "Room",

                "Length",

                "Width",

                "Area",

            ],

        )

        for room in context.rooms:

            schedule.add_row(

                Room=room.name,

                Length=round(room.length,2),

                Width=round(room.width,2),

                Area=round(

                    room.length*room.width,

                    2,

                ),

            )

        return schedule


room_schedule = RoomSchedule()