import uuid

from services.design_engine.interior.objects.furniture import (
    Furniture,
)


def generate(room):

    return [

        Furniture(

            id=str(uuid.uuid4()),

            name="Sofa",

            category="SOFA",

            room=room.name,

            width=7,

            length=3,

        ),

        Furniture(

            id=str(uuid.uuid4()),

            name="Center Table",

            category="TABLE",

            room=room.name,

            width=3,

            length=2,

        ),

        Furniture(

            id=str(uuid.uuid4()),

            name="TV Unit",

            category="TV",

            room=room.name,

            width=5,

            length=1.5,

        ),

    ]