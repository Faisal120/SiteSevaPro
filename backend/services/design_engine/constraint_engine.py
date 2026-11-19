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
                "Living",
                "Living"
            )
        )

        if getattr(body, "dining", True):
            rooms.append(self._create_room("Dining", "Dining"))

        if getattr(body, "kitchen", True):
            rooms.append(self._create_room("Kitchen", "Kitchen"))

        for i in range(body.bedrooms):

            rooms.append(
                self._create_room(
                    f"Bedroom_{i+1}",
                    "Bedroom",
                )
            )

        for i in range(body.bathrooms):

            rooms.append(
                self._create_room(
                    f"Bathroom_{i+1}",
                    "Bathroom"
                )
            )

        if body.parking:

            rooms.append(
                self._create_room(
                    "Parking",
                    "Parking"
                )
            )

        if body.garden:

            rooms.append(
                self._create_room(
                    "Garden",
                    "Garden"
                )
            )

        optional_rooms = (
            ("pooja_room", "Pooja", "Pooja"),
            ("study_room", "Study", "Study"),
            ("store_room", "Store", "Store"),
            ("utility_room", "Utility", "Utility"),
            ("lift", "Lift", "Lift"),
        )
        for field, room_name, room_type in optional_rooms:
            if getattr(body, field, False):
                rooms.append(self._create_room(room_name, room_type))

        if body.floors > 1 or getattr(body, "staircase", True):

            rooms.append(
                self._create_room(
                    "Stair",
                    "Stair"
                )
            )

        return rooms

    def _create_room(
    self,
    room_name,
    room_type,
):

        lib = ROOM_LIBRARY[room_type]

        width, length = lib["sizes"][0]

        rules = BUILDING_RULES.get(
            room_type,
            {},
        )

        return Room(

            name=room_name,

            room_type=room_type,

            width=width,

            length=length,

            preferred_zone=VASTU.get(room_type),

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
