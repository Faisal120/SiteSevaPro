import os
import json
import google.generativeai as genai

genai.configure(
    api_key=os.getenv("AQ.Ab8RN6Lqapl-cqL7oYNzpvwLIXuO2EG5hLUG1VEPhNaHmMAZ-g")
)

model = genai.GenerativeModel(
    "gemini-2.5-flash"
)

def generate_floor_plan(data):

    prompt = f"""
You are a professional architect.

Generate a realistic residential floor plan.

Plot Width:
{data['plot_width']} feet

Plot Length:
{data['plot_length']} feet

Facing:
{data['facing']}

Bedrooms:
{data['bedrooms']}

Bathrooms:
{data['bathrooms']}

Floors:
{data['floors']}

Return ONLY JSON.

Format:

{{
    "rooms":[
        {{
            "name":"Living Room",
            "type":"living",
            "x":0,
            "y":0,
            "width":14,
            "height":16
        }}
    ]
}}

Rules:

- all dimensions in feet
- no overlap
- include kitchen
- include parking
- include stairs if floors > 1
- realistic architecture
- valid JSON only
"""

    response = model.generate_content(
        prompt
    )

    text = response.text.strip()

    text = (
        text
        .replace("```json", "")
        .replace("```", "")
    )

    return json.loads(text)