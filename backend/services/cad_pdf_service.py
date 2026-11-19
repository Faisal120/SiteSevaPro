"""A3 CAD-style PDF sheets generated from the canonical 2D layout model.

These sheets are conceptual design deliverables. Structural members, sizes and
reinforcement must be reviewed and issued by a licensed structural engineer.
"""

from datetime import datetime
from io import BytesIO
from math import ceil

from reportlab.lib import colors
from reportlab.lib.pagesizes import A3, landscape
from reportlab.lib.styles import getSampleStyleSheet
from reportlab.lib.units import mm
from reportlab.platypus import Table, TableStyle
from reportlab.pdfgen import canvas


class CadPdfService:
    SHEET_SIZE = landscape(A3)
    TITLE_HEIGHT = 132
    DRAWING_TYPES = {
        "FLOOR", "ELECTRICAL", "PLUMBING", "COLUMN", "STRUCTURAL",
        "FOUNDATION", "DOOR_WINDOW",
    }

    def build(self, layout, drawing_type="FLOOR", project_name="Untitled Project", site_id=""):
        drawing_type = drawing_type.upper()
        if drawing_type not in self.DRAWING_TYPES:
            raise ValueError("Unsupported PDF drawing type.")

        stream = BytesIO()
        pdf = canvas.Canvas(stream, pagesize=self.SHEET_SIZE)
        pdf.setTitle(f"SiteSeva Pro - {drawing_type.title()} Drawing")
        self._draw_sheet(pdf, layout, drawing_type, project_name, site_id)
        pdf.save()
        return stream.getvalue()

    def _draw_sheet(self, pdf, layout, drawing_type, project_name, site_id):
        page_width, page_height = self.SHEET_SIZE
        pdf.setStrokeColor(colors.HexColor("#4b5563"))
        pdf.setLineWidth(.5)
        pdf.rect(12 * mm, 12 * mm, page_width - 24 * mm, page_height - 24 * mm)

        plot = layout["plot"]
        rooms = layout.get("rooms", [])
        plan = self._plan_frame(plot, page_width, page_height)
        self._draw_grid(pdf, plan, plot)
        self._draw_floor_plan(pdf, plan, rooms, drawing_type)
        self._draw_dimensions(pdf, plan, plot)
        self._draw_discipline(pdf, plan, rooms, drawing_type)
        self._draw_legend(pdf, drawing_type, plan)
        self._draw_title_block(pdf, drawing_type, project_name, site_id, plot)

        if drawing_type == "DOOR_WINDOW":
            pdf.showPage()
            self._draw_schedule_sheet(pdf, layout, project_name, site_id)

    def _plan_frame(self, plot, page_width, page_height):
        right_reserved = 255 if plot["width"] / max(plot["length"], 1) < .8 else 180
        left = 48
        bottom = self.TITLE_HEIGHT + 38
        available_width = page_width - left - right_reserved - 36
        available_height = page_height - bottom - 88
        scale = min(available_width / plot["width"], available_height / plot["length"])
        return {
            "x": left + (available_width - plot["width"] * scale) / 2,
            "top": bottom + (available_height + plot["length"] * scale) / 2,
            "scale": scale,
            "width": plot["width"] * scale,
            "height": plot["length"] * scale,
            "page_width": page_width,
        }

    def _point(self, plan, x, y):
        return plan["x"] + x * plan["scale"], plan["top"] - y * plan["scale"]

    def _draw_grid(self, pdf, plan, plot):
        pdf.saveState()
        pdf.setStrokeColor(colors.HexColor("#9ca3af"))
        pdf.setDash(5, 4)
        pdf.setLineWidth(.45)
        cols = max(2, min(6, ceil(plot["width"] / 10)))
        rows = max(2, min(8, ceil(plot["length"] / 10)))
        for i in range(cols + 1):
            x = plan["x"] + plan["width"] * i / cols
            pdf.line(x, plan["top"] + 22, x, plan["top"] - plan["height"] - 22)
            pdf.setFillColor(colors.white)
            pdf.circle(x, plan["top"] + 38, 12, fill=1)
            pdf.setStrokeColor(colors.HexColor("#4b5563"))
            pdf.circle(x, plan["top"] + 38, 12, fill=0)
            pdf.setFillColor(colors.black)
            pdf.setFont("Helvetica-Bold", 11)
            pdf.drawCentredString(x, plan["top"] + 34, chr(65 + i))
        for i in range(rows + 1):
            y = plan["top"] - plan["height"] * i / rows
            pdf.setStrokeColor(colors.HexColor("#9ca3af"))
            pdf.line(plan["x"] - 22, y, plan["x"] + plan["width"] + 22, y)
            pdf.setFillColor(colors.white)
            pdf.circle(plan["x"] - 38, y, 12, fill=1)
            pdf.setStrokeColor(colors.HexColor("#4b5563"))
            pdf.circle(plan["x"] - 38, y, 12, fill=0)
            pdf.setFillColor(colors.black)
            pdf.setFont("Helvetica-Bold", 11)
            pdf.drawCentredString(plan["x"] - 38, y - 4, str(i + 1))
        pdf.restoreState()

    def _draw_floor_plan(self, pdf, plan, rooms, drawing_type):
        pdf.saveState()
        for room in rooms:
            x, y = self._point(plan, room["x"], room["y"] + room["height"])
            w = room["width"] * plan["scale"]
            h = room["height"] * plan["scale"]
            pdf.setFillColor(colors.HexColor("#f8fafc"))
            pdf.setStrokeColor(colors.HexColor("#111827"))
            pdf.setLineWidth(2.2)
            pdf.rect(x, y, w, h, fill=1)
            pdf.setFillColor(colors.HexColor("#111827"))
            pdf.setFont("Helvetica-Bold", max(7, min(11, w / 18)))
            pdf.drawCentredString(x + w / 2, y + h / 2 + 3, room["name"].replace("_", " ").upper())
            pdf.setFont("Helvetica", max(6, min(8, w / 24)))
            pdf.drawCentredString(x + w / 2, y + h / 2 - 9, f'{room["width"]:.1f}\' x {room["height"]:.1f}\'')
            if room["name"] == "Parking":
                self._draw_vehicle(pdf, x, y, w, h)

        # A conceptual entrance gate at the facing edge is always visible.
        gate = min(plan["width"] * .26, 100)
        gx = plan["x"] + (plan["width"] - gate) / 2
        gy = plan["top"] - plan["height"]
        pdf.setFillColor(colors.white)
        pdf.setStrokeColor(colors.black)
        pdf.setLineWidth(1.1)
        pdf.line(gx, gy, gx + gate / 2, gy - gate / 4)
        pdf.line(gx + gate, gy, gx + gate / 2, gy - gate / 4)
        pdf.setFont("Helvetica-Bold", 7)
        pdf.drawCentredString(gx + gate / 2, gy - gate / 4 - 12, "ENTRANCE GATE")
        pdf.restoreState()

    def _draw_vehicle(self, pdf, x, y, width, height):
        car_w, car_h = min(width * .42, 70), min(height * .58, 150)
        car_x, car_y = x + width * .12, y + (height - car_h) / 2
        pdf.setStrokeColor(colors.HexColor("#374151"))
        pdf.setLineWidth(1)
        pdf.roundRect(car_x, car_y, car_w, car_h, car_w * .15, fill=0)
        pdf.rect(car_x + car_w * .15, car_y + car_h * .2, car_w * .7, car_h * .25, fill=0)
        if width > 150:
            bx, by = car_x + car_w + 24, y + height * .45
            pdf.circle(bx, by, 7, fill=0)
            pdf.circle(bx + 25, by, 7, fill=0)
            pdf.line(bx, by, bx + 10, by + 18)
            pdf.line(bx + 10, by + 18, bx + 25, by)

    def _draw_dimensions(self, pdf, plan, plot):
        pdf.saveState()
        pdf.setStrokeColor(colors.HexColor("#2563eb"))
        pdf.setLineWidth(.6)
        x1, x2 = plan["x"], plan["x"] + plan["width"]
        y_top, y_bottom = plan["top"], plan["top"] - plan["height"]
        pdf.line(x1, y_top + 16, x2, y_top + 16)
        pdf.line(x1, y_top + 11, x1, y_top + 21)
        pdf.line(x2, y_top + 11, x2, y_top + 21)
        pdf.setFillColor(colors.HexColor("#1d4ed8"))
        pdf.setFont("Helvetica-Bold", 9)
        pdf.drawCentredString((x1 + x2) / 2, y_top + 22, f'{plot["width"]:.2f}\' [PLOT WIDTH]')
        pdf.line(x1 - 16, y_bottom, x1 - 16, y_top)
        pdf.saveState()
        pdf.translate(x1 - 26, (y_top + y_bottom) / 2)
        pdf.rotate(90)
        pdf.drawCentredString(0, 0, f'{plot["length"]:.2f}\' [PLOT LENGTH]')
        pdf.restoreState()
        pdf.restoreState()

    def _draw_discipline(self, pdf, plan, rooms, drawing_type):
        if drawing_type == "FLOOR" or drawing_type == "DOOR_WINDOW":
            return
        pdf.saveState()
        if drawing_type == "ELECTRICAL":
            pdf.setStrokeColor(colors.red)
            for room in rooms:
                x, y = self._point(plan, room["x"] + room["width"] / 2, room["y"] + room["height"] / 2)
                pdf.circle(x, y, 5, fill=0)
                pdf.line(x - 8, y, x + 8, y)
                pdf.line(x, y - 8, x, y + 8)
        elif drawing_type == "PLUMBING":
            pdf.setStrokeColor(colors.blue)
            for room in rooms:
                if room["name"].split("_")[0] in {"Bathroom", "Kitchen", "Utility"}:
                    x, y = self._point(plan, room["x"] + room["width"] / 2, room["y"] + room["height"] / 2)
                    pdf.circle(x, y, 5, fill=0)
                    pdf.line(x, y, plan["x"] + plan["width"], plan["top"] - plan["height"])
        else:
            colour = colors.HexColor("#7c3aed" if drawing_type == "COLUMN" else "#dc2626")
            pdf.setStrokeColor(colour)
            pdf.setDash(4, 3)
            spacing = max(85, min(145, plan["width"] / 4))
            x = plan["x"]
            while x <= plan["x"] + plan["width"] + 1:
                pdf.line(x, plan["top"], x, plan["top"] - plan["height"])
                y = plan["top"] - plan["height"]
                while y <= plan["top"] + 1:
                    pdf.setDash()
                    pdf.rect(x - 4, y - 4, 8, 8, fill=0)
                    pdf.setDash(4, 3)
                    y += spacing
                x += spacing
            if drawing_type in {"STRUCTURAL", "FOUNDATION"}:
                y = plan["top"] - plan["height"]
                while y <= plan["top"] + 1:
                    pdf.line(plan["x"], y, plan["x"] + plan["width"], y)
                    y += spacing
        pdf.restoreState()

    def _draw_legend(self, pdf, drawing_type, plan):
        if drawing_type == "FLOOR":
            entries = [("Wall", "#111827"), ("Grid / dimension", "#2563eb"), ("Entrance gate", "#111827")]
        elif drawing_type == "ELECTRICAL":
            entries = [("Light point", "#dc2626"), ("Switch circuit", "#dc2626"), ("Distribution board", "#b91c1c")]
        elif drawing_type == "PLUMBING":
            entries = [("Cold water line", "#2563eb"), ("Plumbing point", "#2563eb"), ("Riser / stack", "#1d4ed8")]
        elif drawing_type in {"COLUMN", "STRUCTURAL", "FOUNDATION"}:
            entries = [("Column location", "#7c3aed" if drawing_type == "COLUMN" else "#dc2626"), ("Beam / grid", "#dc2626"), ("Engineer review required", "#b45309")]
        else:
            entries = [("Door schedule", "#111827"), ("Window schedule", "#111827"), ("Verify sizes on site", "#b45309")]

        x = plan["x"] + plan["width"] + 30
        y = plan["top"] - 15
        pdf.setFillColor(colors.white)
        pdf.setStrokeColor(colors.HexColor("#6b7280"))
        pdf.roundRect(x, y - 120, 150, 120, 6, fill=1)
        pdf.setFillColor(colors.black)
        pdf.setFont("Helvetica-Bold", 10)
        pdf.drawString(x + 10, y - 18, "LEGEND")
        for index, (label, colour) in enumerate(entries):
            yy = y - 42 - index * 23
            pdf.setStrokeColor(colors.HexColor(colour))
            pdf.setLineWidth(2)
            pdf.line(x + 12, yy, x + 34, yy)
            pdf.setFillColor(colors.HexColor("#374151"))
            pdf.setFont("Helvetica", 7)
            pdf.drawString(x + 43, yy - 3, label)

    def _draw_title_block(self, pdf, drawing_type, project_name, site_id, plot):
        page_width, _ = self.SHEET_SIZE
        y, h = 20, 102
        x = 32
        widths = [260, 250, 155, 160, 155, page_width - x - 980]
        labels = [
            "SITESEVA PRO\nCONCEPTUAL DESIGN STUDIO",
            "NOTES:\n1. ALL DIMENSIONS ARE IN FEET.\n2. VERIFY ON SITE BEFORE EXECUTION.\n3. NOT FOR CONSTRUCTION WITHOUT PROFESSIONAL APPROVAL.",
            f"PROJECT:\n{project_name or 'UNTITLED PROJECT'}\nSITE: {site_id or '-'}",
            f"DRAWING DETAILS:\n{drawing_type.replace('_', ' ')} PLAN\nSCALE: FIT TO SHEET",
            f"PLOT:\n{plot['width']} x {plot['length']} FT\nFACING: {plot['facing']}",
            f"DATE: {datetime.now().strftime('%d-%m-%Y')}\nDRAWING NO.: SSP-{drawing_type[:3]}-01\nREVISION: R0",
        ]
        cursor = x
        for width, label in zip(widths, labels):
            pdf.setStrokeColor(colors.HexColor("#4b5563"))
            pdf.roundRect(cursor, y, width - 5, h, 5, fill=0)
            pdf.setFillColor(colors.black)
            pdf.setFont("Helvetica-Bold", 6.5)
            for line_no, line in enumerate(label.split("\n")):
                pdf.drawString(cursor + 8, y + h - 15 - line_no * 10, line[:52])
            cursor += width
        pdf.setFont("Helvetica-Bold", 18)
        pdf.drawString(32, y + h + 16, f"{drawing_type.replace('_', ' ')} DRAWING")

    def _draw_schedule_sheet(self, pdf, layout, project_name, site_id):
        page_width, page_height = self.SHEET_SIZE
        pdf.setFont("Helvetica-Bold", 24)
        pdf.drawString(36, page_height - 52, "DOOR & WINDOW SCHEDULE")
        pdf.setFont("Helvetica", 10)
        pdf.drawString(36, page_height - 70, f"Project: {project_name or 'Untitled Project'}  |  Site: {site_id or '-'}")
        doors = layout.get("doors", [])
        windows = layout.get("windows", [])
        rows = [["TYPE", "ID", "WIDTH (FT)", "LOCATION / CONNECTED ROOMS", "REMARKS"]]
        rows += [["DOOR", f"D{index + 1}", f"{door.get('width', 3):.1f}", f"{door.get('room_a', '-') } - {door.get('room_b', '-')}", "Verify shutter/height on site"] for index, door in enumerate(doors)]
        rows += [["WINDOW", f"W{index + 1}", f"{window.get('width', 4):.1f}", window.get("room", "-"), f"{window.get('wall', '').upper()} wall"] for index, window in enumerate(windows)]
        table = Table(rows, colWidths=[70, 50, 85, 330, 220], repeatRows=1)
        table.setStyle(TableStyle([
            ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#111827")),
            ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
            ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
            ("FONTNAME", (0, 1), (-1, -1), "Helvetica"),
            ("FONTSIZE", (0, 0), (-1, -1), 8),
            ("GRID", (0, 0), (-1, -1), .4, colors.HexColor("#9ca3af")),
            ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
            ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, colors.HexColor("#f8fafc")]),
            ("TOPPADDING", (0, 0), (-1, -1), 7),
            ("BOTTOMPADDING", (0, 0), (-1, -1), 7),
        ]))
        _, table_height = table.wrapOn(pdf, page_width - 72, page_height - 160)
        table.drawOn(pdf, 36, max(145, page_height - 105 - table_height))
        self._draw_title_block(pdf, "DOOR_WINDOW", project_name, site_id, layout["plot"])


cad_pdf_service = CadPdfService()
