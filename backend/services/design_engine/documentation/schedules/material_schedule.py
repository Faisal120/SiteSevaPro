from .schedule_base import Schedule


class MaterialSchedule:

    def generate(
        self,
        context,
    ):

        schedule = Schedule(

            title="Material Estimate",

            columns=[

                "Item",

                "Quantity",

            ],

        )

        schedule.add_row(

            Item="Wall Length",

            Quantity=round(

                sum(

                    w.length

                    for w in context.walls

                ),

                2,

            ),

        )

        return schedule


material_schedule = MaterialSchedule()