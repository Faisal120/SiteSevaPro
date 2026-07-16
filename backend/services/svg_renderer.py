"""
SVG Renderer

Converts AI Layout JSON
into Professional SVG Drawings.

SiteSeva Pro
"""

from xml.etree.ElementTree import Element
from xml.etree.ElementTree import SubElement
from xml.etree.ElementTree import tostring
from datetime import datetime

import math

class SVGRenderer:
    
    ROOM_COLORS = {

    "Living": "#F3F4F6",

    "Bedroom": "#EFF6FF",

    "Kitchen": "#FEF3C7",

    "Bathroom": "#FCE7F3",

    "Dining": "#ECFCCB",

    "Store": "#F3E8FF",

    "Stair": "#E5E7EB",

    }

    SCALE = 20

    WALL = 8

    FONT = 18

    PADDING = 80

    def __init__(self):

        self.svg = None

        self.width = 0

        self.height = 0

        self.layout = None

    # ======================================================
    # PUBLIC
    # ======================================================

    def render(
        self,
        layout,
    ):

        self.layout = layout

        plot = layout["plot"]

        self.width = (
            plot["width"] * self.SCALE
            + self.PADDING * 2
        )

        self.height = (
            plot["length"] * self.SCALE
            + self.PADDING * 2
        )

        self._create_svg()

        self._draw_background()

        self._draw_plot()

        # Next Parts
        self._draw_rooms()
        
        self._draw_rooms()
        
        self._draw_corridors()

        self._draw_doors()

        self._draw_windows()

        self._draw_stairs()

        self._draw_parking()

        self._draw_garden()

        self._draw_compass()

        self._draw_scale()

        self._draw_title()
        
        self._draw_dimensions()

        self._draw_legend()

        self._draw_branding()

        return tostring(
            self.svg,
            encoding="unicode",
        )

    # ======================================================
    # SVG
    # ======================================================

    def _create_svg(self):

        self.svg = Element(

            "svg",

            {

                "xmlns": "http://www.w3.org/2000/svg",

                "width": str(self.width),

                "height": str(self.height),

                "viewBox": f"0 0 {self.width} {self.height}",

            },

        )

    # ======================================================
    # BACKGROUND
    # ======================================================

    def _draw_background(self):

        SubElement(

            self.svg,

            "rect",

            {

                "x": "0",

                "y": "0",

                "width": str(self.width),

                "height": str(self.height),

                "fill": "#ffffff",

            },

        )

    # ======================================================
    # PLOT
    # ======================================================

    def _draw_plot(self):

        plot = self.layout["plot"]

        SubElement(

            self.svg,

            "rect",

            {

                "x": str(self.PADDING),

                "y": str(self.PADDING),

                "width": str(plot["width"] * self.SCALE),

                "height": str(plot["length"] * self.SCALE),

                "fill": "none",

                "stroke": "black",

                "stroke-width": str(self.WALL),

            },

        )

    # ======================================================
    # PLACEHOLDERS
    # ======================================================

    def _draw_rooms(self):

        rooms = self.layout.get(
            "rooms",
            [],
        )

        for room in rooms:

            self._draw_room(room)
            
    def _draw_room(
    self,
    room,
):

        x = self._sx(room["x"])

        y = self._sy(room["y"])

        width = self._sw(room["width"])

        height = self._sh(room["height"])

        self._draw_wall(
            x,
            y,
            x + width,
            y,
        )

        self._draw_wall(
            x,
            y,
            x,
            y + height,
        )

        self._draw_wall(
            x + width,
            y,
            x + width,
            y + height,
        )

        self._draw_wall(
            x,
            y + height,
            x + width,
            y + height,
        )

        self._room_label(
            room,
            x,
            y,
            width,
            height,
        )
        
        
    def _draw_corridors(self):

        for corridor in self.layout.get(

            "corridors",

            [],

        ):

            SubElement(

                self.svg,

                "rect",

                {

                    "x": str(

                        self._sx(

                            corridor["x"]

                        )

                    ),

                    "y": str(

                        self._sy(

                            corridor["y"]

                        )

                    ),

                    "width": str(

                        self._sw(

                            corridor["width"]

                        )

                    ),

                    "height": str(

                        self._sh(

                            corridor["height"]

                        )

                    ),

                    "fill": "#ECECEC",

                    "stroke": "#999",

                    "stroke-width": "1",

                },

            )
        
    def _room_label(

    self,

    room,

    x,

    y,

    width,

    height,

):

        cx = x + width / 2

        cy = y + height / 2

        name = room.get(
            "name",
            "",
        )

        size = f'{room["width"]} x {room["height"]}'

        SubElement(

            self.svg,

            "text",

            {

                "x": str(cx),

                "y": str(cy - 8),

                "text-anchor": "middle",

                "font-size": "18",

                "font-family": "Arial",

                "font-weight": "bold",

                "fill": "#111827",

            },

        ).text = name

        SubElement(

            self.svg,

            "text",

            {

                "x": str(cx),

                "y": str(cy + 16),

                "text-anchor": "middle",

                "font-size": "12",

                "font-family": "Arial",

                "fill": self.ROOM_COLORS.get(
                room["name"],
                "#FFFFFF",
            ),

            },

        ).text = size

    def _draw_wall(

        self,

        x1,

        y1,

        x2,

        y2,

    ):

        SubElement(

            self.svg,

            "line",

            {

                "x1": str(x1),

                "y1": str(y1),

                "x2": str(x2),

                "y2": str(y2),

                "stroke": "black",

                "stroke-width": "6",

            },

        )
        
        

    def _draw_doors(self):

        for door in self.layout.get(

            "doors",

            [],

        ):

            x = self._sx(door["x"])

            y = self._sy(door["y"])

            width = self._sw(door["width"])

            wall = door["wall"]

            if wall in ("east", "west"):

                SubElement(

                    self.svg,

                    "line",

                    {

                        "x1": str(x),

                        "y1": str(y - width / 2),

                        "x2": str(x),

                        "y2": str(y + width / 2),

                        "stroke": "#2563EB",

                        "stroke-width": "4",

                    },

                )

            else:

                SubElement(

                    self.svg,

                    "line",

                    {

                        "x1": str(x - width / 2),

                        "y1": str(y),

                        "x2": str(x + width / 2),

                        "y2": str(y),

                        "stroke": "#2563EB",

                        "stroke-width": "4",

                    },

                )
            

    def _draw_door(
        self,
        door,
    ):

        x = self._sx(door["x"])

        y = self._sy(door["y"])

        width = self._sw(door["width"])

        wall = door.get(
            "wall",
            "north",
        )

        if wall == "north":

            x1 = x

            y1 = y

            x2 = x + width

            y2 = y

            arc_x = x + width

            arc_y = y + width

        elif wall == "south":

            x1 = x

            y1 = y

            x2 = x + width

            y2 = y

            arc_x = x

            arc_y = y - width

        elif wall == "east":

            x1 = x

            y1 = y

            x2 = x

            y2 = y + width

            arc_x = x - width

            arc_y = y

        else:

            x1 = x

            y1 = y

            x2 = x

            y2 = y + width

            arc_x = x + width

            arc_y = y

        SubElement(

            self.svg,

            "line",

            {

                "x1": str(x1),

                "y1": str(y1),

                "x2": str(x2),

                "y2": str(y2),

                "stroke": "#2563EB",

                "stroke-width": "2",

            },

        )

        path = f"M{x1},{y1} Q{arc_x},{arc_y} {x2},{y2}"

        SubElement(

            self.svg,

            "path",

            {

                "d": path,

                "stroke": "#9CA3AF",

                "fill": "none",

                "stroke-width": "1.5",

                "stroke-dasharray": "5 3",

            },

        )
        
        
    def _draw_windows(self):

        for window in self.layout.get(

            "windows",

            [],

        ):

            self._draw_window(window)
            
    def _draw_window(
    self,
    window,
):

        x = self._sx(window["x"])

        y = self._sy(window["y"])

        width = self._sw(window["width"])

        wall = window.get(

            "wall",

            "north",

        )

        if wall in ("north", "south"):

            SubElement(

                self.svg,

                "line",

                {

                    "x1": str(x),

                    "y1": str(y),

                    "x2": str(x + width),

                    "y2": str(y),

                    "stroke": "#06B6D4",

                    "stroke-width": "4",

                },

            )

        else:

            SubElement(

                self.svg,

                "line",

                {

                    "x1": str(x),

                    "y1": str(y),

                    "x2": str(x),

                    "y2": str(y + width),

                    "stroke": "#06B6D4",

                    "stroke-width": "4",

                },

            )

    def _draw_stairs(self):

        for stair in self.layout.get(

            "stairs",

            [],

        ):

            x=self._sx(stair["x"])

            y=self._sy(stair["y"])

            w=self._sw(stair["width"])

            h=self._sh(stair["height"])

            steps=10

            step=h/steps

            for i in range(steps):

                yy=y+i*step

                SubElement(

                    self.svg,

                    "line",

                    {

                        "x1":str(x),

                        "y1":str(yy),

                        "x2":str(x+w),

                        "y2":str(yy),

                        "stroke":"#444",

                        "stroke-width":"1",

                    },

                )

            SubElement(

                self.svg,

                "text",

                {

                    "x":str(x+w/2),

                    "y":str(y+h+16),

                    "text-anchor":"middle",

                    "font-size":"12",

                },

            ).text="STAIR ↑"
            
    def _draw_legend(self):

        x=20

        y=20

        items=[

            ("Wall","#000"),

            ("Door","#2563EB"),

            ("Window","#06B6D4"),

            ("Garden","green"),

            ("Parking","#777"),

        ]

        for i,(label,color) in enumerate(items):

            yy=y+i*20

            SubElement(

                self.svg,

                "rect",

                {

                    "x":str(x),

                    "y":str(yy),

                    "width":"12",

                    "height":"12",

                    "fill":color,

                },

            )

            SubElement(

                self.svg,

                "text",

                {

                    "x":str(x+18),

                    "y":str(yy+11),

                    "font-size":"12",

                },

            ).text=label

    def _draw_parking(self):

        for parking in self.layout.get(

            "parking",

            [],

        ):

            x = self._sx(parking["x"])

            y = self._sy(parking["y"])

            w = self._sw(parking["width"])

            h = self._sh(parking["height"])

            SubElement(

                self.svg,

                "rect",

                {

                    "x": str(x),

                    "y": str(y),

                    "width": str(w),

                    "height": str(h),

                    "fill":"#F5F5F5",

                    "stroke":"#777",

                    "stroke-dasharray":"5 5",

                },

            )

            SubElement(

                self.svg,

                "text",

                {

                    "x":str(x+w/2),

                    "y":str(y+h/2),

                    "text-anchor":"middle",

                    "font-size":"14",

                },

            ).text="PARKING"
            
    def _draw_branding(self):

        company=self.layout.get(

            "company_name",

            "SiteSeva Pro",

        )

        SubElement(

            self.svg,

            "text",

            {

                "x":"30",

                "y":str(self.height-70),

                "font-size":"18",

                "font-weight":"bold",

            },

        ).text=company

    def _draw_garden(self):

        for garden in self.layout.get(

            "garden",

            [],

        ):

            x=self._sx(garden["x"])

            y=self._sy(garden["y"])

            w=self._sw(garden["width"])

            h=self._sh(garden["height"])

            SubElement(

                self.svg,

                "rect",

                {

                    "x":str(x),

                    "y":str(y),

                    "width":str(w),

                    "height":str(h),

                    "fill":"#DCFCE7",

                    "stroke":"green",

                },

            )

            SubElement(

                self.svg,

                "text",

                {

                    "x":str(x+w/2),

                    "y":str(y+h/2),

                    "text-anchor":"middle",

                    "font-size":"14",

                },

            ).text="GARDEN"

    def _draw_compass(self):

        cx = self.width - 70

        cy = 70

        r = 22

        SubElement(

            self.svg,

            "circle",

            {

                "cx": str(cx),

                "cy": str(cy),

                "r": str(r),

                "fill": "white",

                "stroke": "black",

                "stroke-width": "2",

            },

        )

        SubElement(

            self.svg,

            "line",

            {

                "x1": str(cx),

                "y1": str(cy + r),

                "x2": str(cx),

                "y2": str(cy - r),

                "stroke": "black",

                "stroke-width": "2",

            },

        )

        SubElement(

            self.svg,

            "polygon",

            {

                "points": f"{cx},{cy-r-10} {cx-6},{cy-r+2} {cx+6},{cy-r+2}",

                "fill": "black",

            },

        )

        SubElement(

            self.svg,

            "text",

            {

                "x": str(cx),

                "y": str(cy-r-18),

                "text-anchor": "middle",

                "font-size": "14",

                "font-weight": "bold",

            },

        ).text = "N"

    def _draw_scale(self):

        x = 60

        y = self.height - 35

        length = 200

        SubElement(

            self.svg,

            "line",

            {

                "x1": str(x),

                "y1": str(y),

                "x2": str(x + length),

                "y2": str(y),

                "stroke": "black",

                "stroke-width": "3",

            },

        )

        for i in range(5):

            xx = x + i * 50

            SubElement(

                self.svg,

                "line",

                {

                    "x1": str(xx),

                    "y1": str(y - 6),

                    "x2": str(xx),

                    "y2": str(y + 6),

                    "stroke": "black",

                    "stroke-width": "2",

                },

            )

            SubElement(

                self.svg,

                "text",

                {

                    "x": str(xx),

                    "y": str(y + 24),

                    "text-anchor": "middle",

                    "font-size": "12",

                },

            ).text = str(i * 5)

        SubElement(

            self.svg,

            "text",

            {

                "x": str(x + length + 20),

                "y": str(y + 24),

                "font-size": "12",

            },

        ).text = "Feet"
        
    def _draw_dimensions(self):

        plot = self.layout["plot"]

        x = self.PADDING

        y = self.PADDING

        w = self._sw(plot["width"])

        h = self._sh(plot["length"])

        offset = 35

        # Top Dimension

        SubElement(

            self.svg,

            "line",

            {

                "x1": str(x),

                "y1": str(y-offset),

                "x2": str(x+w),

                "y2": str(y-offset),

                "stroke": "#444",

                "stroke-width": "1",

            },

        )

        SubElement(

            self.svg,

            "text",

            {

                "x": str(x+w/2),

                "y": str(y-offset-6),

                "text-anchor":"middle",

                "font-size":"12",

            },

        ).text = f'{plot["width"]} ft'

        # Left Dimension

        SubElement(

            self.svg,

            "line",

            {

                "x1": str(x-offset),

                "y1": str(y),

                "x2": str(x-offset),

                "y2": str(y+h),

                "stroke":"#444",

                "stroke-width":"1",

            },

        )

        SubElement(

            self.svg,

            "text",

            {

                "x": str(x-offset-10),

                "y": str(y+h/2),

                "font-size":"12",

                "transform":f"rotate(-90 {x-offset-10},{y+h/2})",

            },

        ).text = f'{plot["length"]} ft'

    

    def _draw_title(self):

        box_width = 340

        box_height = 90

        x = self.width - box_width - 20

        y = self.height - box_height - 20

        SubElement(

            self.svg,

            "rect",

            {

                "x": str(x),

                "y": str(y),

                "width": str(box_width),

                "height": str(box_height),

                "fill": "white",

                "stroke": "black",

                "stroke-width": "2",

            },

        )

        project = self.layout.get(

            "project_name",

            "Untitled",

        )

        SubElement(

            self.svg,

            "text",

            {

                "x": str(x + 12),

                "y": str(y + 24),

                "font-size": "16",

                "font-weight": "bold",

            },

        ).text = project

        SubElement(

            self.svg,

            "text",

            {

                "x": str(x + 12),

                "y": str(y + 46),

                "font-size": "12",

            },

        ).text = "SiteSeva Pro AI Design Studio"

        SubElement(

            self.svg,

            "text",

            {

                "x": str(x + 12),

                "y": str(y + 66),

                "font-size": "11",

            },

        ).text = datetime.now().strftime("%d-%m-%Y")

        SubElement(

            self.svg,

            "text",

            {

                "x": str(x + 210),

                "y": str(y + 66),

                "font-size": "11",

            },

        ).text = "Scale : 1:100"
        
    def save(

    self,

    layout,

    path,

):

        svg=self.render(

            layout,

        )

        with open(

            path,

            "w",

            encoding="utf-8",

        ) as f:

            f.write(svg)

        return path

    # ======================================================
    # GEOMETRY
    # ======================================================

    def _sx(self, x):

        return self.PADDING + x * self.SCALE


    def _sy(self, y):

        return self.PADDING + y * self.SCALE


    def _sw(self, w):

        return w * self.SCALE


    def _sh(self, h):

        return h * self.SCALE

svg_renderer = SVGRenderer()