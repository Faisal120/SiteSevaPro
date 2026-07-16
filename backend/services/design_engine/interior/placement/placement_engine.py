from services.design_engine.interior.semantic import relationship_engine, semantic_engine
from services.design_engine.interior.placement.wall_detector import (
    wall_detector,
)

from services.design_engine.interior.placement.anchor_selector import (
    anchor_selector,
)

from services.design_engine.interior.validation.collision_engine import (
    collision_engine,
)

from services.design_engine.interior.validation.clearance_engine import (
    clearance_engine,
)

class PlacementEngine:

    def place(
        self,
        room,
        furniture,
    ):

        walls = wall_detector.detect(room)

        for item in furniture:

            wall = anchor_selector.choose(
                walls,
                item,
            )

            item.wall = wall.name

            ...
            # initial x,y calculation
            ...

        furniture = semantic_engine.apply(

            room,

            furniture,

        )



        furniture = relationship_engine.solve(

            furniture,

        )


        furniture = collision_engine.resolve(

            furniture,

        )

        furniture = clearance_engine.apply(

            furniture,

        )

        return furniture


placement_engine = PlacementEngine()