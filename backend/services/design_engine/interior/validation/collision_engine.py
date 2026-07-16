from services.design_engine.interior.validation.room_bounds import (
    Rectangle,
)


class CollisionEngine:

    def overlaps(
        self,
        a,
        b,
    ):

        ra = Rectangle(
            a.x,
            a.y,
            a.width,
            a.length,
        )

        rb = Rectangle(
            b.x,
            b.y,
            b.width,
            b.length,
        )

        return not (

            ra.right <= rb.left or
            ra.left >= rb.right or
            ra.bottom <= rb.top or
            ra.top >= rb.bottom

        )

    def resolve(
        self,
        furniture,
    ):

        changed = True

        while changed:

            changed = False

            for i in range(len(furniture)):

                for j in range(i + 1, len(furniture)):

                    if self.overlaps(
                        furniture[i],
                        furniture[j],
                    ):

                        furniture[j].x += 0.30

                        changed = True

        return furniture


collision_engine = CollisionEngine()