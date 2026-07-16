from services.design_engine.room_library import ROOM_LIBRARY
from services.design_engine.building_rules import BUILDING_RULES
from services.design_engine.vastu_engine import VASTU
from services.design_engine.types import Room


class ConstraintEngine:

    def build_rooms(
        self,
        body,
    ):

        rooms = []

        rooms.append(
            self._create_room(
                "Living"
            )
        )

        rooms.append(
            self._create_room(
                "Dining"
            )
        )

        rooms.append(
            self._create_room(
                "Kitchen"
            )
        )

        for _ in range(body.bedrooms):

            rooms.append(
                self._create_room(
                    "Bedroom"
                )
            )

        for _ in range(body.bathrooms):

            rooms.append(
                self._create_room(
                    "Bathroom"
                )
            )

        if body.parking:

            rooms.append(
                self._create_room(
                    "Parking"
                )
            )

        if body.garden:

            rooms.append(
                self._create_room(
                    "Garden"
                )
            )

        if body.floors > 1:

            rooms.append(
                self._create_room(
                    "Stair"
                )
            )

        return rooms

    def _create_room(
        self,
        name,
    ):

        lib = ROOM_LIBRARY[name]

        width, length = lib["sizes"][0]

        rules = BUILDING_RULES.get(
            name,
            {},
        )

        return Room(

            name=name,

            width=width,

            length=length,

            preferred_zone=VASTU.get(name),

            adjacent_to=rules.get(
                "adjacent",
                [],
            ),

            avoid=rules.get(
                "avoid",
                [],
            ),

        )


constraint_engine = ConstraintEngine()