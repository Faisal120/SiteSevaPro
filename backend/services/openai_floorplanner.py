import os
import base64
from openai import OpenAI

# ----------------------------------------------------
# Lazy Client Initialization
# ----------------------------------------------------

_client = None


def get_client():
    """
    Returns an initialized OpenAI client.

    Raises a clear error if the API key is missing.
    """

    global _client

    if _client is not None:
        return _client

    api_key = os.getenv("OPENAI_API_KEY")

    if not api_key:
        raise RuntimeError(
            "OPENAI_API_KEY is not configured."
        )

    _client = OpenAI(api_key=api_key)

    return _client


# ----------------------------------------------------
# Image Generation
# ----------------------------------------------------

def generate_floorplan_image(data):

    client = get_client()

    prompt = f"""
Generate a professional architectural 2D floor plan.

Requirements

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

Style

• Modern Indian House
• AutoCAD Style
• Black & White
• Dimension Lines
• Room Labels
• Parking
• Living Room
• Dining
• Kitchen
• Staircase
• Furniture Symbols
• Door Swings
• Windows
• North Arrow
• Scale
• Professional Architectural Drawing

Output

Top View

No Perspective

No Background

High Resolution
"""

    response = client.images.generate(
        model="gpt-image-1",
        prompt=prompt,
        size="1536x1536",
    )

    image_base64 = response.data[0].b64_json

    return base64.b64decode(image_base64)