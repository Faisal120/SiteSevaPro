from services.design_engine.stages import constraint_stage, plot_stage, geometry_stage, packing_stage, overlap_stage, graph_stage, optimization_stage, architecture_stage, export_stage

from .pipeline import Pipeline

from services.design_engine.pipeline import (
    Pipeline,
)

def __init__(self):

    self.pipeline = Pipeline(

    [

        plot_stage,

        constraint_stage,

        # candidate_stage,   # <-- Disable for now

        geometry_stage,

        packing_stage,

        overlap_stage,

        graph_stage,

        optimization_stage,

        validation_stage,

        architecture_stage,

        export_stage,

    ]

)