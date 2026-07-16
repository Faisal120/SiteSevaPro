import uuid

from services.design_engine.interior.objects.furniture import (
    Furniture,
)


def generate(room):

    return [

        Furniture(

            id=str(uuid.uuid4()),

            name="Dining Table",

            category="DINING",

            room=room.name,

            width=6,

            length=4,

        ),

    ]