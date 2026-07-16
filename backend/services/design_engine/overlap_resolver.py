"""
Overlap Resolver

Moves rooms until
no overlaps remain.
"""

class OverlapResolver:

    GAP = 1

    def resolve(

        self,

        rooms,

    ):

        changed = True

        while changed:

            changed = False

            for i in range(len(rooms)):

                for j in range(i + 1, len(rooms)):

                    if self._overlap(

                        rooms[i],

                        rooms[j],

                    ):

                        rooms[j].x += self.GAP

                        changed = True

        return rooms

    def _overlap(

        self,

        a,

        b,

    ):

        return not (

            a.x + a.width <= b.x

            or

            b.x + b.width <= a.x

            or

            a.y + a.length <= b.y

            or

            b.y + b.length <= a.y

        )


overlap_resolver = OverlapResolver()