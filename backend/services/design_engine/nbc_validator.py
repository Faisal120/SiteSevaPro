"""
NBC Validator

National Building Code
Minimum Sizes
"""

class NBCValidator:

    RULES = {

        "Bedroom": 100,

        "Living": 120,

        "Kitchen": 50,

        "Bathroom": 20,

        "Dining": 60,

    }

    def validate(

        self,

        rooms,

    ):

        errors = []

        for room in rooms:

            minimum = self.RULES.get(

                room.name

            )

            if minimum is None:

                continue

            area = room.width * room.length

            if area < minimum:

                errors.append(

                    {

                        "room": room.name,

                        "required": minimum,

                        "actual": area,

                    }

                )

        return errors


nbc_validator = NBCValidator()