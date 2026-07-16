from .room_schedule import room_schedule

from .door_schedule import door_schedule

from .window_schedule import window_schedule

from .area_schedule import area_schedule

from .material_schedule import material_schedule


class ScheduleEngine:

    def generate(
        self,
        context,
    ):

        return [

            room_schedule.generate(context),

            door_schedule.generate(context),

            window_schedule.generate(context),

            area_schedule.generate(context),

            material_schedule.generate(context),

        ]


schedule_engine = ScheduleEngine()