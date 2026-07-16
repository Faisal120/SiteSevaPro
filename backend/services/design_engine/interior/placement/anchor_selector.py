"""
Chooses best wall for furniture.
"""


class AnchorSelector:

    def choose(

        self,

        walls,

        furniture,

    ):

        longest = max(

            walls,

            key=lambda w: w.length,

        )

        return longest


anchor_selector = AnchorSelector()