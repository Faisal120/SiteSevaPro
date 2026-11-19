"""Site-level symbols used by the clean floor-plan SVG."""


class SiteFeatureRenderer:

    def render(self, context, plot, rooms):
        parking = next((room for room in rooms if room.room_type == "Parking"), None)
        if parking:
            self._draw_vehicle_symbols(context, parking)

        self._draw_entrance_gate(context, plot)
        return context

    def _draw_vehicle_symbols(self, context, parking):
        x = context.margin + parking.x * context.scale
        y = context.margin + parking.y * context.scale
        width = parking.width * context.scale
        height = parking.length * context.scale

        # Simple CAD-style car symbol, sized within the actual parking bay.
        car_width = min(width * 0.48, 95)
        car_height = min(height * 0.7, 220)
        car_x = x + max(10, width * 0.12)
        car_y = y + max(10, (height - car_height) / 2)
        context.elements.append(
            f'''<g fill="none" stroke="#4b5563" stroke-width="2">
                <rect x="{car_x}" y="{car_y}" width="{car_width}" height="{car_height}" rx="{car_width * .18}" />
                <rect x="{car_x + car_width * .12}" y="{car_y + car_height * .18}" width="{car_width * .76}" height="{car_height * .28}" rx="4" />
                <line x1="{car_x}" y1="{car_y + car_height * .72}" x2="{car_x + car_width}" y2="{car_y + car_height * .72}" />
            </g>'''
        )

        # Bike symbol sits beside the car when the bay is sufficiently wide.
        if width > 170:
            bx = car_x + car_width + 25
            by = y + height * 0.58
            context.elements.append(
                f'''<g fill="none" stroke="#4b5563" stroke-width="2">
                    <circle cx="{bx}" cy="{by}" r="9" /><circle cx="{bx + 30}" cy="{by}" r="9" />
                    <path d="M {bx} {by} L {bx + 12} {by - 24} L {bx + 22} {by} L {bx + 8} {by}" />
                    <line x1="{bx + 12}" y1="{by - 24}" x2="{bx + 25}" y2="{by - 27}" />
                </g>'''
            )

    def _draw_entrance_gate(self, context, plot):
        x = context.margin
        y = context.margin
        width = plot.width * context.scale
        height = plot.length * context.scale
        facing = plot.facing.upper()
        gate = min(150, max(90, (width if facing in {"NORTH", "SOUTH"} else height) * .28))

        if facing in {"NORTH", "SOUTH"}:
            gy = y if facing == "NORTH" else y + height
            gx = x + (width - gate) / 2
            context.elements.append(
                f'''<g fill="none" stroke="#111827" stroke-width="2">
                    <line x1="{gx}" y1="{gy}" x2="{gx + gate / 2}" y2="{gy + (-gate / 3 if facing == 'NORTH' else gate / 3)}" />
                    <line x1="{gx + gate}" y1="{gy}" x2="{gx + gate / 2}" y2="{gy + (-gate / 3 if facing == 'NORTH' else gate / 3)}" />
                    <text x="{gx + gate / 2}" y="{gy + (-gate / 3 - 10 if facing == 'NORTH' else gate / 3 + 16)}" text-anchor="middle" font-size="11" fill="#111827">ENTRANCE GATE</text>
                </g>'''
            )
        else:
            gx = x if facing == "WEST" else x + width
            gy = y + (height - gate) / 2
            direction = -1 if facing == "WEST" else 1
            context.elements.append(
                f'''<g fill="none" stroke="#111827" stroke-width="2">
                    <line x1="{gx}" y1="{gy}" x2="{gx + direction * gate / 3}" y2="{gy + gate / 2}" />
                    <line x1="{gx}" y1="{gy + gate}" x2="{gx + direction * gate / 3}" y2="{gy + gate / 2}" />
                    <text x="{gx + direction * 52}" y="{gy + gate / 2}" text-anchor="middle" font-size="11" fill="#111827">ENTRANCE</text>
                </g>'''
            )


site_feature_renderer = SiteFeatureRenderer()
