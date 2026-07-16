from .schedule_base import Schedule


class WindowSchedule:

    def generate(
        self,
        context,
    ):

        schedule = Schedule(

            title="Window Schedule",

            columns=[

                "ID",

                "Width",

                "Height",

                "Room",

            ],

        )

        for i, window in enumerate(context.windows):

            schedule.add_row(

                ID=f"W{i+1}",

                Width=window.width,

                Height=window.height,

                Room=window.room,

            )

        return schedule


window_schedule = WindowSchedule()