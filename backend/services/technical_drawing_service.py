"""Technical drawing overlays derived from the authoritative 2D layout."""

from html import escape


class TechnicalDrawingService:
    DRAWING_TYPES = {
        "ELECTRICAL", "PLUMBING", "COLUMN", "STRUCTURAL", "FOUNDATION",
        "DOOR_WINDOW",
    }

    def render(self, layout, drawing_type):
        drawing_type = drawing_type.upper()
        if drawing_type not in self.DRAWING_TYPES:
            raise ValueError("Unsupported technical drawing type.")

        svg = layout.get("svg", "")
        if not svg:
            raise ValueError("The base floor plan is missing.")

        plot = layout["plot"]
        rooms = layout.get("rooms", [])
        scale = 25
        margin = 80
        overlay = self._overlay(plot, rooms, drawing_type, scale, margin)
        return {
            "type": drawing_type,
            "title": f"{drawing_type.title()} Plan",
            "svg": svg.replace("</svg>", overlay + "</svg>"),
        }

    def _overlay(self, plot, rooms, drawing_type, scale, margin):
        room_centres = [
            (
                room,
                margin + (room["x"] + room["width"] / 2) * scale,
                margin + (room["y"] + room["height"] / 2) * scale,
            )
            for room in rooms
        ]
        title = escape(f"{drawing_type.title()} Overlay")
        items = [
            '<g class="technical-overlay">',
            f'<rect x="{margin + 8}" y="{margin + 8}" width="210" height="28" rx="4" fill="white" stroke="#111827" />',
            f'<text x="{margin + 18}" y="{margin + 27}" font-size="12" font-weight="700">{title}</text>',
        ]

        if drawing_type == "ELECTRICAL":
            items.extend(self._electrical(room_centres, margin))
        elif drawing_type == "PLUMBING":
            items.extend(self._plumbing(room_centres, margin, plot, scale))
        elif drawing_type in {"COLUMN", "STRUCTURAL", "FOUNDATION"}:
            items.extend(self._structure(plot, drawing_type, margin, scale))
        else:
            items.append(
                f'<text x="{margin + 18}" y="{margin + 56}" font-size="12">Download the PDF sheet for the complete door and window schedule.</text>'
            )

        items.append("</g>")
        return "".join(items)

    def _electrical(self, room_centres, margin):
        panel_x, panel_y = margin + 18, margin + 55
        parts = [
            f'<rect x="{panel_x}" y="{panel_y}" width="18" height="24" fill="#fef3c7" stroke="#b45309" />',
            f'<text x="{panel_x + 25}" y="{panel_y + 16}" font-size="10" fill="#92400e">DB</text>',
        ]
        for room, x, y in room_centres:
            parts.append(f'<line x1="{panel_x + 18}" y1="{panel_y + 12}" x2="{x}" y2="{y}" stroke="#d97706" stroke-width="1.5" stroke-dasharray="4 3" />')
            parts.append(f'<circle cx="{x}" cy="{y}" r="7" fill="#fef3c7" stroke="#d97706" stroke-width="2" />')
            parts.append(f'<path d="M {x - 2} {y - 5} L {x + 2} {y} L {x - 1} {y} L {x + 2} {y + 5}" fill="none" stroke="#d97706" stroke-width="1.5" />')
        return parts

    def _plumbing(self, room_centres, margin, plot, scale):
        riser_x = margin + plot["width"] * scale - 16
        riser_y = margin + plot["length"] * scale - 16
        parts = [
            f'<circle cx="{riser_x}" cy="{riser_y}" r="9" fill="#dbeafe" stroke="#2563eb" stroke-width="2" />',
            f'<text x="{riser_x - 5}" y="{riser_y + 3}" font-size="8" fill="#1d4ed8">R</text>',
        ]
        for room, x, y in room_centres:
            room_type = room["name"].split("_")[0].lower()
            if room_type in {"bathroom", "kitchen", "utility"}:
                parts.append(f'<line x1="{riser_x}" y1="{riser_y}" x2="{x}" y2="{y}" stroke="#2563eb" stroke-width="2" stroke-dasharray="5 3" />')
                parts.append(f'<circle cx="{x}" cy="{y}" r="6" fill="#dbeafe" stroke="#2563eb" stroke-width="2" />')
        return parts

    def _structure(self, plot, drawing_type, margin, scale):
        width = plot["width"] * scale
        height = plot["length"] * scale
        colour = "#7c3aed" if drawing_type == "COLUMN" else "#dc2626"
        parts = []
        spacing = 150
        for x in range(int(margin), int(margin + width) + 1, spacing):
            parts.append(f'<line x1="{x}" y1="{margin}" x2="{x}" y2="{margin + height}" stroke="{colour}" stroke-width="1.5" stroke-dasharray="6 4" />')
            for y in range(int(margin), int(margin + height) + 1, spacing):
                parts.append(f'<rect x="{x - 5}" y="{y - 5}" width="10" height="10" fill="white" stroke="{colour}" stroke-width="2" />')
        if drawing_type in {"STRUCTURAL", "FOUNDATION"}:
            for y in range(int(margin), int(margin + height) + 1, spacing):
                parts.append(f'<line x1="{margin}" y1="{y}" x2="{margin + width}" y2="{y}" stroke="{colour}" stroke-width="1.5" stroke-dasharray="6 4" />')
        return parts


technical_drawing_service = TechnicalDrawingService()
