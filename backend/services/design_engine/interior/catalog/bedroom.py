import uuid

from services.design_engine.interior.objects.furniture import (
    Furniture,
)


def generate(room):

    bed = Furniture(

        id=str(uuid.uuid4()),

        name="Queen Bed",

        category="BED",

        room=room.name,

        width=6.0,

        length=6.5,

    )

    wardrobe = Furniture(

        id=str(uuid.uuid4()),

        name="Wardrobe",

        category="WARDROBE",

        room=room.name,

        width=6.0,

        length=2.0,

    )

    return [

        bed,

        wardrobe,

    ]