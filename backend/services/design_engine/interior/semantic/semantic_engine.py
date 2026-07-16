from services.design_engine.interior.semantic import (

    bedroom_rules,

    living_rules,

    kitchen_rules,

    bathroom_rules,

    dining_rules,

)


class SemanticEngine:

    def apply(

        self,

        room,

        furniture,

    ):

        room_type = room.name.lower()

        if "bed" in room_type:

            return bedroom_rules.apply(

                room,

                furniture,

            )

        if "living" in room_type:

            return living_rules.apply(

                room,

                furniture,

            )

        if "kitchen" in room_type:

            return kitchen_rules.apply(

                room,

                furniture,

            )

        if "bath" in room_type:

            return bathroom_rules.apply(

                room,

                furniture,

            )

        if "dining" in room_type:

            return dining_rules.apply(

                room,

                furniture,

            )

        return furniture


semantic_engine = SemanticEngine()