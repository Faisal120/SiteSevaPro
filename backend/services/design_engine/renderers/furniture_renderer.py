"""Monochrome CAD furniture blocks for the conceptual 2D drawing sheet."""


class FurnitureRenderer:
    STROKE = "#4b5563"

    def render(self, context, rooms):
        for room in rooms:
            x = context.margin + room.x * context.scale
            y = context.margin + room.y * context.scale
            w, h = room.width * context.scale, room.length * context.scale
            name = room.name.lower()
            if "bed" in name:
                self._bed(context, x, y, w, h)
            elif "living" in name:
                self._living(context, x, y, w, h)
            elif "kitchen" in name:
                self._kitchen(context, x, y, w, h)
            elif "dining" in name:
                self._dining(context, x, y, w, h)
            elif "bath" in name or "toilet" in name:
                self._bath(context, x, y, w, h)
        return context

    def _add(self, context, svg):
        context.elements.append(f'<g fill="white" stroke="{self.STROKE}" stroke-width="1.35">{svg}</g>')

    def _bed(self, context, x, y, w, h):
        bx, by, bw, bh = x+w*.18, y+h*.16, w*.6, h*.6
        self._add(context, f'<rect x="{bx}" y="{by}" width="{bw}" height="{bh}" rx="3"/><rect x="{bx+bw*.08}" y="{by+bh*.08}" width="{bw*.36}" height="{bh*.16}" rx="2"/><rect x="{bx+bw*.56}" y="{by+bh*.08}" width="{bw*.36}" height="{bh*.16}" rx="2"/><line x1="{bx}" y1="{by+bh*.26}" x2="{bx+bw}" y2="{by+bh*.26}"/><rect x="{x+w*.08}" y="{y+h*.12}" width="{w*.09}" height="{h*.12}" rx="2"/><rect x="{x+w*.81}" y="{y+h*.12}" width="{w*.09}" height="{h*.12}" rx="2"/>')

    def _living(self, context, x, y, w, h):
        self._add(context, f'<rect x="{x+w*.12}" y="{y+h*.14}" width="{w*.68}" height="{h*.2}" rx="7"/><rect x="{x+w*.12}" y="{y+h*.34}" width="{w*.12}" height="{h*.35}" rx="5"/><rect x="{x+w*.68}" y="{y+h*.34}" width="{w*.12}" height="{h*.35}" rx="5"/><rect x="{x+w*.35}" y="{y+h*.51}" width="{w*.26}" height="{h*.18}"/><line x1="{x+w*.35}" y1="{y+h*.6}" x2="{x+w*.61}" y2="{y+h*.6}"/>')

    def _kitchen(self, context, x, y, w, h):
        self._add(context, f'<path d="M {x+w*.08} {y+h*.1} H {x+w*.82} V {y+h*.25} H {x+w*.25} V {y+h*.82} H {x+w*.08} Z"/><rect x="{x+w*.36}" y="{y+h*.1}" width="{w*.18}" height="{h*.12}" rx="2"/><circle cx="{x+w*.65}" cy="{y+h*.16}" r="{min(w,h)*.055}"/><circle cx="{x+w*.75}" cy="{y+h*.16}" r="{min(w,h)*.055}"/>')

    def _dining(self, context, x, y, w, h):
        tx, ty, tw, th = x+w*.27, y+h*.3, w*.45, h*.32
        chairs = [(tx-tw*.16,ty+th*.12),(tx+tw*1.04,ty+th*.12),(tx+tw*.15,ty-th*.27),(tx+tw*.15,ty+th*1.04)]
        self._add(context, f'<rect x="{tx}" y="{ty}" width="{tw}" height="{th}" rx="4"/>' + ''.join(f'<rect x="{cx}" y="{cy}" width="{tw*.16}" height="{th*.42}" rx="2"/>' for cx,cy in chairs))

    def _bath(self, context, x, y, w, h):
        self._add(context, f'<ellipse cx="{x+w*.28}" cy="{y+h*.3}" rx="{w*.13}" ry="{h*.17}"/><rect x="{x+w*.65}" y="{y+h*.18}" width="{w*.2}" height="{h*.2}" rx="2"/><circle cx="{x+w*.75}" cy="{y+h*.28}" r="{min(w,h)*.035}"/><path d="M {x+w*.18} {y+h*.65} h {w*.58} v {h*.17} h -{w*.58} z"/>')


furniture_renderer = FurnitureRenderer()
