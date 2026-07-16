import uuid

from services.design_engine.interior.objects.furniture import (
    Furniture,
)


def generate(room):

    return [

        Furniture(

            id=str(uuid.uuid4()),

            name="Kitchen Counter",

            category="COUNTER",

            room=room.name,

            width=8,

            length=2,

        ),

        Furniture(

            id=str(uuid.uuid4()),

            name="Refrigerator",

            category="FRIDGE",

            room=room.name,

            width=2.5,

            length=2.5,

        ),

    ]