"""Pure builders for approved WhatsApp template components."""
from __future__ import annotations

from typing import Any


def authentication_components(code: str, button_index: str = "0") -> list[dict[str, Any]]:
    """Meta Authentication / Copy Code send components (body + OTP URL button)."""
    return [
        {"type": "body", "parameters": [{"type": "text", "text": code}]},
        {
            "type": "button",
            "sub_type": "url",
            "index": str(button_index),
            "parameters": [{"type": "text", "text": code}],
        },
    ]
