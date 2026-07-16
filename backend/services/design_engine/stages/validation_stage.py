"""
Validation Stage
"""

from services.design_engine.validator import (
    layout_validator,
)

from services.design_engine.resize_engine import (
    resize_engine,
)

from services.design_engine.geometry_engine import (
    geometry_engine,
)

from services.design_engine.nbc_validator import (
    nbc_validator,
)


class ValidationStage:

    def run(
        self,
        context,
    ):

        if not layout_validator.validate(

            context.rooms,

            context.plot,

        ):

            context.rooms = resize_engine.shrink_all(

                context.rooms

            )

            context.rooms = geometry_engine.place(

                context.rooms,

                context.plot,

                context.zones,

            )

        context.errors = nbc_validator.validate(

            context.rooms

        )

        return context


validation_stage = ValidationStage()