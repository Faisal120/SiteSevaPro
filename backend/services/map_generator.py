import os
import requests
import cloudinary.uploader

GEMINI_API_KEY = os.getenv(
    "GEMINI_API_KEY"
)

async def generate_floor_plan(
    prompt: str
):

    url = (
        "https://generativelanguage.googleapis.com/v1beta/models/"
        "gemini-2.0-flash-preview-image-generation:generateContent"
        f"?key={GEMINI_API_KEY}"
    )

    payload = {
        "contents": [
            {
                "parts": [
                    {
                        "text": prompt
                    }
                ]
            }
        ]
    }

    response = requests.post(
        url,
        json=payload,
        timeout=120
    )

    response.raise_for_status()

    data = response.json()

    # first implementation:
    # return raw response for debugging

    return data