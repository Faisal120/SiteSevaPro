import os
import base64
from openai import OpenAI

client = OpenAI(
    api_key=os.getenv("OPENAI_API_KEY")
)


def generate_floorplan_image(data):

    prompt = f"""
Generate a professional architectural 2D floor plan.

Requirements:

Plot Size:
{data['plot_width']} x {data['plot_length']} Feet

Facing:
{data['facing']}

Bedrooms:
{data['bedrooms']}

Bathrooms:
{data['bathrooms']}

Floors:
{data['floors']}

Requirements:

• Modern Indian House
• AutoCAD Style
• Black and White
• Dimension Lines
• Room Labels
• Parking
• Living Room
• Dining
• Kitchen
• Staircase
• Furniture Symbols
• Door Swing
• Windows
• North Direction
• Scale
• Professional Architectural Drawing

Output:
Top View Only

No Perspective

No Background

High Resolution
"""

    result = client.images.generate(
        model="gpt-image-1",
        prompt=prompt,
        size="1536x1536"
    )

    image_base64 = result.data[0].b64_json

    return base64.b64decode(image_base64)