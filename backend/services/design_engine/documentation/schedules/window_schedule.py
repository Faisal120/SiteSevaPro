from .schedule_base import Schedule


class WindowSchedule:
    
    print("Loaded WindowSchedule:", __file__)

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
            

            print(type(window))
            print(vars(window))

            schedule.add_row(
                ID=f"W{i+1}",
                Width=getattr(window, "width", ""),
                Height=getattr(window, "height", ""),
                Room=getattr(window, "room", ""),
            )

            schedule.add_row(
                ID=f"W{i+1}",
                Width=window.width,
                Height="-",          # or "N/A"
                Room=window.room,
            )
            
        print("\n========== WINDOWS ==========")

        for i, window in enumerate(context.windows):
            print(type(window))
            print(vars(window))

        print("=============================\n")

        return schedule


window_schedule = WindowSchedule()