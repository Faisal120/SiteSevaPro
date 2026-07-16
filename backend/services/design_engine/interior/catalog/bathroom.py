import uuid

from services.design_engine.interior.objects.furniture import (
    Furniture,
)


def generate(room):

    return [

        Furniture(

            id=str(uuid.uuid4()),

            name="WC",

            category="TOILET",

            room=room.name,

            width=2,

            length=2,

        ),

        Furniture(

            id=str(uuid.uuid4()),

            name="Wash Basin",

            category="BASIN",

            room=room.name,

            width=1.5,

            length=1,

        ),

        Furniture(

            id=str(uuid.uuid4()),

            name="Shower",

            category="SHOWER",

            room=room.name,

            width=3,

            length=3,

        ),

    ]