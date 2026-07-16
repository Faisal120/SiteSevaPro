from services.design_engine.renderers import (
    svg_renderer,
)

class JsonRenderer:

    def render(
        self,
        context,
    ):
        
        svg = svg_renderer.render(

            {

                "plot": context.plot,

                "rooms": context.rooms,

                "doors": context.doors,

                "windows": context.windows,

            }

        )

        return {

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

            "doors": context.doors,

            "windows": context.windows,

            "corridors": context.corridors,

            "graph": context.graph_json,

            "stairs": context.stairs,

            "parking": context.parking,

            "garden": context.garden,

            "score": context.score,

            "validation_errors": context.errors,
            
            "svg": svg,
            
            "schedules":context.schedules,

            "drawings":context.drawings,
            
            "exports":context.exports,

        }


json_renderer = JsonRenderer()