from dataclasses import dataclass


@dataclass
class Canvas:

    width: int = 1600

    height: int = 1200

    margin: int = 80

    scale: float = 1

    offset_x: float = 0

    offset_y: float = 0

    def fit(self, plot_width, plot_length):

        usable_width = self.width - self.margin * 2

        usable_height = self.height - self.margin * 2

        self.scale = min(

            usable_width / plot_width,

            usable_height / plot_length,

        )

        self.offset_x = (

            self.width - plot_width * self.scale

        ) / 2

        self.offset_y = (

            self.height - plot_length * self.scale

        ) / 2