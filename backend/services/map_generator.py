import os
import base64
import cloudinary.uploader

from openai import OpenAI

client = OpenAI(
    api_key=os.getenv(
        "OPENAI_API_KEY"
    )
)

async def generate_floor_plan(
    prompt: str
):

    result = client.images.generate(
        model="gpt-image-1",
        prompt=prompt,
        size="1024x1024"
    )

    image_base64 = (
        result.data[0].b64_json
    )

    image_bytes = base64.b64decode(
        image_base64
    )

    upload = cloudinary.uploader.upload(
        image_bytes,
        folder="siteseva/maps"
    )

    return upload["secure_url"]