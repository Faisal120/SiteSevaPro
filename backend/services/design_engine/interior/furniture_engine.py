from services.design_engine.interior.placement import placement_engine
from services.design_engine.interior.catalog import (

    bedroom,

    kitchen,

    living,

    bathroom,

    dining,

)


class FurnitureEngine:

    def generate(

        self,

        rooms,

    ):

        furniture = []

        for room in rooms:

            name = room.name.lower()

            if "bed" in name:

                items = bedroom.generate(

                    room

                )

                items = placement_engine.place(

                    room,

                    items,

                )

                furniture.extend(

                    items

                )

            elif "living" in name:

                furniture.extend(

                    living.generate(room)

                )

            elif "kitchen" in name:

                furniture.extend(

                    kitchen.generate(room)

                )

            elif "bath" in name:

                furniture.extend(

                    bathroom.generate(room)

                )

            elif "dining" in name:

                furniture.extend(

                    dining.generate(room)

                )

        return furniture


furniture_engine = FurnitureEngine()