import json
import asyncio

from openai import AsyncOpenAI

from core.config import settings

from services.prompt_builder import PromptBuilder

client = AsyncOpenAI(
    api_key=settings.OPENAI_API_KEY,
)


class LayoutEngine:

    MAX_RETRIES = 3

    # =====================================================
    # PUBLIC
    # =====================================================

    async def generate(
        self,
        body,
    ):

        prompt = PromptBuilder.build(
            body,
        )

        last_error = None

        for attempt in range(self.MAX_RETRIES):

            try:

                response = await self._ask_ai(
                    prompt,
                )

                layout = self._parse_json(
                    response,
                )

                self._validate(
                    layout,
                )

                return layout

            except Exception as e:

                last_error = e

                await asyncio.sleep(
                    1,
                )

        raise Exception(
            f"Layout generation failed: {last_error}"
        )

    # =====================================================
    # OPENAI
    # =====================================================

    async def _ask_ai(
        self,
        prompt: str,
    ):

        response = await client.chat.completions.create(

            model="gpt-5",

            temperature=0.2,

            messages=[

                {

                    "role": "system",

                    "content": "You are India's best architect.",

                },

                {

                    "role": "user",

                    "content": prompt,

                },

            ],

        )

        return response.choices[0].message.content

    # =====================================================
    # JSON
    # =====================================================

    def _parse_json(
        self,
        text,
    ):

        text = text.strip()

        if text.startswith("```"):

            text = (
                text.replace("```json", "")
                .replace("```", "")
                .strip()
            )

        return json.loads(
            text,
        )

    # =====================================================
    # VALIDATION
    # =====================================================

    def _validate(
        self,
        layout,
    ):

        required = [

            "plot",

            "rooms",

            "doors",

            "windows",

            "stairs",

            "parking",

            "garden",

        ]

        for field in required:

            if field not in layout:

                raise Exception(
                    f"{field} missing"
                )

        self._validate_plot(
            layout["plot"],
        )

        self._validate_rooms(
            layout["rooms"],
        )

    # =====================================================
    # PLOT
    # =====================================================

    def _validate_plot(
        self,
        plot,
    ):

        required = [

            "width",

            "length",

            "facing",

        ]

        for item in required:

            if item not in plot:

                raise Exception(
                    "Invalid Plot"
                )

    # =====================================================
    # ROOMS
    # =====================================================

    def _validate_rooms(
        self,
        rooms,
    ):

        if not isinstance(
            rooms,
            list,
        ):

            raise Exception(
                "Rooms must be list"
            )

        if len(rooms) == 0:

            raise Exception(
                "No rooms generated"
            )

        for room in rooms:

            self._validate_room(
                room,
            )

    # =====================================================
    # ROOM
    # =====================================================

    def _validate_room(
        self,
        room,
    ):

        required = [

            "name",

            "x",

            "y",

            "width",

            "height",

        ]

        for field in required:

            if field not in room:

                raise Exception(
                    f"{field} missing in room"
                )

        if room["width"] <= 0:

            raise Exception(
                "Invalid room width"
            )

        if room["height"] <= 0:

            raise Exception(
                "Invalid room height"
            )

    # =====================================================
    # OPTIONAL VALIDATORS
    # =====================================================

    def validate_doors(
        self,
        doors,
    ):

        if not isinstance(
            doors,
            list,
        ):

            raise Exception(
                "Doors must be list"
            )

    def validate_windows(
        self,
        windows,
    ):

        if not isinstance(
            windows,
            list,
        ):

            raise Exception(
                "Windows must be list"
            )

    def validate_stairs(
        self,
        stairs,
    ):

        if not isinstance(
            stairs,
            list,
        ):

            raise Exception(
                "Stairs must be list"
            )


layout_engine = LayoutEngine()