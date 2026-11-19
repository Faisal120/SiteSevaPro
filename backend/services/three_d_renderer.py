"""Architectural open-top, axonometric SVG renderer for approved floor plans.

This is deliberately separate from the 2D CAD output: it is a furnished
presentation view, with open ceilings and raised perimeter/partition walls.
It remains a concept renderer, not a construction or photorealistic render.
"""
from html import escape


class ThreeDRenderer:
    def render(self, layout: dict, floor_number: int) -> str:
        plot, rooms = layout.get("plot", {}), layout.get("rooms", [])
        width, length = float(plot.get("width", 30)), float(plot.get("length", 40))
        scale, ox, oy, wall = 12, 520, 116, 60

        def pt(x, y, z=0):
            return ox + (x - y) * scale, oy + (x + y) * scale * .52 - z

        def polygon(points, fill, stroke="#8d8d88", stroke_width=1.5):
            values = " ".join(f"{x:.1f},{y:.1f}" for x, y in points)
            return f'<polygon points="{values}" fill="{fill}" stroke="{stroke}" stroke-width="{stroke_width}" stroke-linejoin="round"/>'

        def prism(x, y, w, h, height, top, front="#bdb8af", side="#aaa69f"):
            p1, p2, p3, p4 = pt(x, y), pt(x + w, y), pt(x + w, y + h), pt(x, y + h)
            t1, t2, t3, t4 = pt(x, y, height), pt(x + w, y, height), pt(x + w, y + h, height), pt(x, y + h, height)
            return "".join((polygon([p1, p4, t4, t1], front), polygon([p2, p3, t3, t2], side), polygon([t1, t2, t3, t4], top, "#6c6962")))

        site = [pt(-1.5, -1.5), pt(width + 1.5, -1.5), pt(width + 1.5, length + 1.5), pt(-1.5, length + 1.5)]
        out = [
            '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1080 820" role="img">',
            '<defs><filter id="shadow"><feDropShadow dx="0" dy="7" stdDeviation="7" flood-opacity=".22"/></filter></defs>',
            '<rect width="1080" height="820" fill="#d7d3cd"/>',
            '<text x="42" y="48" fill="#172033" font-family="Arial, sans-serif" font-size="22" font-weight="700">FURNISHED 3D CONCEPT · ', escape("GROUND FLOOR" if floor_number == 1 else f"FLOOR {floor_number - 1}"), '</text>',
            '<text x="42" y="72" fill="#596579" font-family="Arial, sans-serif" font-size="12">Open-top architectural presentation • based on selected 2D plan</text>',
            polygon(site, "#c8c0b3", "#aaa195", 2),
            '<g filter="url(#shadow)">',
        ]
        palette = ["#f2e8d8", "#e5edf0", "#eee3d5", "#e0eadc", "#f0e7de", "#e9e4d8"]
        for index, room in enumerate(rooms):
            x, y = float(room["x"]), float(room["y"])
            rw, rh = float(room["width"]), float(room.get("height", room.get("length", 1)))
            base = [pt(x, y), pt(x + rw, y), pt(x + rw, y + rh), pt(x, y + rh)]
            out.append(polygon(base, palette[index % len(palette)], "#b4aca1", 1.2))
            # These raised faces give every room a clean, open-top cutaway.
            out.append(polygon([base[0], base[3], pt(x, y + rh, wall), pt(x, y, wall)], "#e6e3de", "#807c75", 2))
            out.append(polygon([base[1], base[2], pt(x + rw, y + rh, wall), pt(x + rw, y, wall)], "#d2d0cb", "#807c75", 2))
            out.extend(self._furniture(room["name"].lower(), x, y, rw, rh, pt, prism, polygon))
            cx, cy = pt(x + rw * .5, y + rh * .54, 8)
            out.append(f'<text x="{cx:.1f}" y="{cy:.1f}" text-anchor="middle" fill="#263548" font-family="Arial, sans-serif" font-size="11" font-weight="700">{escape(room["name"].upper())}</text>')
        out.extend(("</g>", '<g font-family="Arial, sans-serif"><rect x="770" y="720" width="260" height="62" rx="7" fill="#f7f5f0" stroke="#8f8a80"/><text x="786" y="746" font-size="12" fill="#172033" font-weight="700">SITESEVA PRO · CONCEPT ONLY</text><text x="786" y="767" font-size="11" fill="#566174">Verify dimensions and materials with your architect.</text></g>', "</svg>"))
        return "".join(out)

    def _furniture(self, name, x, y, w, h, pt, prism, polygon):
        items = []
        if "bed" in name:
            items.extend((prism(x + w*.18, y + h*.2, w*.58, h*.52, 15, "#cdb08a", "#a58164", "#927057"), prism(x + w*.21, y + h*.23, w*.52, h*.15, 20, "#f5f1ea", "#d7d1c8", "#beb7ad")))
        elif "living" in name:
            items.extend((prism(x + w*.13, y + h*.14, w*.7, h*.18, 16, "#69747c", "#4f5960", "#3d474f"), prism(x + w*.4, y + h*.53, w*.23, h*.18, 13, "#b58d61", "#8f6849", "#76543b")))
        elif "dining" in name:
            items.append(prism(x + w*.25, y + h*.28, w*.5, h*.38, 18, "#8b6246", "#704936", "#5a392a"))
            for dx, dy in ((.16,.28),(.75,.28),(.16,.64),(.75,.64)):
                items.append(prism(x + w*dx, y + h*dy, w*.1, h*.13, 13, "#72513a", "#5d3f2e", "#4b3225"))
        elif "kitchen" in name:
            items.extend((prism(x + w*.08, y + h*.08, w*.15, h*.78, 25, "#59636c", "#414a52", "#303940"), prism(x + w*.08, y + h*.68, w*.7, h*.16, 25, "#59636c", "#414a52", "#303940")))
        elif "bath" in name or "toilet" in name:
            items.extend((prism(x + w*.15, y + h*.2, w*.28, h*.3, 12, "#f3f6f6", "#d2dadd", "#b9c4c7"), prism(x + w*.63, y + h*.22, w*.16, h*.2, 15, "#e9eeee", "#c8d2d4", "#acbabd")))
        elif "parking" in name:
            items.append(prism(x + w*.22, y + h*.15, w*.42, h*.7, 23, "#dfe6e9", "#b8c2c7", "#94a2a8"))
            items.append(prism(x + w*.73, y + h*.55, w*.14, h*.28, 8, "#3f4b57", "#27313a", "#1f2930"))
        return items


three_d_renderer = ThreeDRenderer()
