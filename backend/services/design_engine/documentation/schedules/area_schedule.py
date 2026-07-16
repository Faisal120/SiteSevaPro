from .schedule_base import Schedule


class AreaSchedule:

    def generate(
        self,
        context,
    ):

        carpet = 0

        for room in context.rooms:

            carpet += room.width * room.length

        schedule = Schedule(

            title="Area Statement",

            columns=[

                "Type",

                "Area",

            ],

        )

        schedule.add_row(

            Type="Carpet Area",

            Area=round(carpet,2),

        )

        schedule.add_row(

            Type="Built-up Area",

            Area=round(carpet*1.12,2),

        )

        schedule.add_row(

            Type="Plot Area",

            Area=round(

                context.plot.width *

                context.plot.length,

                2,

            ),

        )

        return schedule


area_schedule = AreaSchedule()