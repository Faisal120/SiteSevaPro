from services.design_engine.stages import plot_stage
from services.design_engine.stages import constraint_stage
from services.design_engine.stages import packing_stage
from services.design_engine.stages import validation_stage
from services.design_engine.stages import architecture_stage
from services.design_engine.stages import export_stage
# from services.design_engine.stages import candidate_stage


from services.design_engine.context import (
    DesignContext,
)

from services.design_engine.pipeline import (
    Pipeline,
)



class DesignEngine:
    
    def __init__(self):

        self.pipeline = Pipeline(
    [
        plot_stage,
        constraint_stage,
        packing_stage,
        validation_stage,
        architecture_stage,
        export_stage,
    ]
)
    
    def generate(self, body):

        context = DesignContext()

        context.body = body

        context = self.pipeline.run(context)

        return context
    

design_engine = DesignEngine()
