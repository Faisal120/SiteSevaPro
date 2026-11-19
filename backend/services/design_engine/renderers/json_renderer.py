from services.design_engine.renderers import (
    svg_renderer,
)
from services.design_engine.window_engine import window_engine
from services.design_engine.door_engine import door_engine
from dataclasses import asdict, is_dataclass

class JsonRenderer:

    def render(
        self,
        context,
    ):
            
        def serialize(obj):
                if is_dataclass(obj):
                    return asdict(obj)
        
                if isinstance(obj, list):
                    return [serialize(x) for x in obj]
        
                if isinstance(obj, dict):
                    return {k: serialize(v) for k, v in obj.items()}
        
                return obj
        
        svg = svg_renderer.render(

            {

                "plot": context.plot,

                "rooms": context.rooms,

                "doors": door_engine.to_json(
                getattr(context, "doors", [])
                    ),

                "windows": window_engine.to_json(
                    getattr(context, "windows", [])
                    ),

            }

        )

        response = {
            "plot": {
                "width": context.plot.width,
                "length": context.plot.length,
                "facing": context.plot.facing,
            },

            "rooms": [
                {
                    "name": room.name,
                    "x": room.x,
                    "y": room.y,
                    "width": room.width,
                    "height": room.length,
                }
                for room in context.rooms
            ],

            "doors": getattr(context, "doors", []),
            "windows": getattr(context, "windows", []),
            "corridors": getattr(context, "corridors", []),
            "stairs": getattr(context, "stairs", []),
            "parking": getattr(context, "parking", None),
            "garden": getattr(context, "garden", None),
            "graph": getattr(context, "graph_json", {}),
            "score": getattr(context, "score", 0),
            "validation_errors": getattr(context, "errors", []),
            "svg": svg,
            "schedules": getattr(context, "schedules", []),
            "drawings": getattr(context, "drawings", []),
            "exports": getattr(context, "exports", {}),
        }

        return serialize(response)


json_renderer = JsonRenderer()