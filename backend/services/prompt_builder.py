class PromptBuilder:

    @staticmethod
    def build(body):

        vastu = "YES" if getattr(body, "vastu", False) else "NO"

        parking = "YES" if getattr(body, "parking", False) else "NO"

        garden = "YES" if getattr(body, "garden", False) else "NO"

        balcony = "YES" if getattr(body, "balcony", False) else "NO"

        return f"""
You are India's best Architect.

Design an optimized residential floor plan.

Follow these rules.

• Follow National Building Code (NBC India).

• Maximize ventilation.

• Maximize natural lighting.

• Maintain proper circulation.

• Room sizes should be practical.

• Use standard wall thickness.

• Return VALID JSON ONLY.

• Never return markdown.

• Never explain.

• Never write comments.

• Never wrap JSON inside ```.

--------------------------------

PROJECT

Project Name:
{body.project_name}

Purpose:
{body.purpose}

--------------------------------

PLOT

Width:
{body.plot_width}

Length:
{body.plot_length}

Facing:
{body.facing}

--------------------------------

BUILDING

Floors:
{body.floors}

Bedrooms:
{body.bedrooms}

Bathrooms:
{body.bathrooms}

Kitchen:
{body.kitchen}

Parking:
{parking}

Garden:
{garden}

Balcony:
{balcony}

Vastu:
{vastu}

--------------------------------

Return ONLY this JSON format.

{{
    "plot": {{
        "width": number,
        "length": number,
        "facing": string
    }},

    "rooms":[
        {{
            "name":"Living",
            "x":0,
            "y":0,
            "width":10,
            "height":12
        }}
    ],

    "doors":[
        {{
            "x":0,
            "y":0,
            "width":3,
            "wall":"north"
        }}
    ],

    "windows":[
        {{
            "x":0,
            "y":0,
            "width":4,
            "wall":"east"
        }}
    ],

    "stairs":[
        {{
            "x":0,
            "y":0,
            "width":6,
            "height":12
        }}
    ],

    "parking":[
        {{
            "x":0,
            "y":0,
            "width":10,
            "height":15
        }}
    ],

    "garden":[
        {{
            "x":0,
            "y":0,
            "width":8,
            "height":10
        }}
    ]
}}
"""
