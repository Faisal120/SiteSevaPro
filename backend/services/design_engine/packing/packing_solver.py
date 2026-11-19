from services.design_engine.packing.packing_model import PackedRoom


class PackingSolver:
    """Create a predictable, construction-drawing-friendly room grid.

    The old implementation started every room at a random coordinate and then
    tried to improve it.  That made the same request produce different plans
    and left the renderer with overlapping or disconnected rooms.  A clean
    2D plan needs an explicit, repeatable partition before it needs an
    optimisation pass.
    """

    def solve(
        self,
        rooms,
        plot,
        variation=0,
    ):

        if not rooms:
            return []

        # Taller plots read better with more horizontal rows.  The balanced
        # partition keeps all rooms contiguous, so doors can be generated on
        # shared walls without inventing corridor geometry.
        # Every regenerate request gets a deterministic alternate arrangement.
        # It remains reproducible for a given variation number, which makes it
        # safe to save, compare and reopen later.
        variation = max(0, int(variation or 0))
        if len(rooms) > 1 and variation:
            shift = variation % len(rooms)
            rooms = rooms[shift:] + rooms[:shift]

        room_count = len(rooms)
        row_count = max(1, round((room_count * plot.length / plot.width) ** 0.5))
        row_count = min(room_count, row_count)

        counts = [room_count // row_count] * row_count
        for index in range(room_count % row_count):
            counts[index] += 1

        grouped_rooms = []
        cursor = 0
        for count in counts:
            grouped_rooms.append(rooms[cursor:cursor + count])
            cursor += count

        # Give rows proportional height according to their requested areas;
        # each row still fills the plot exactly.
        row_weights = [
            max(1.0, sum(room.width * room.length for room in row))
            for row in grouped_rooms
        ]
        total_weight = sum(row_weights)
        y = 0.0
        packed = []

        for row_index, row in enumerate(grouped_rooms):
            row_height = (
                plot.length - y
                if row_index == len(grouped_rooms) - 1
                else plot.length * row_weights[row_index] / total_weight
            )
            room_weights = [max(1.0, room.width * room.length) for room in row]
            room_total = sum(room_weights)
            x = 0.0

            for room_index, room in enumerate(row):
                room_width = (
                    plot.width - x
                    if room_index == len(row) - 1
                    else plot.width * room_weights[room_index] / room_total
                )
                packed.append(PackedRoom(
                    room=room,
                    x=round(x, 3),
                    y=round(y, 3),
                    width=round(room_width, 3),
                    height=round(row_height, 3),
                ))
                x += room_width
            y += row_height

        return packed


packing_solver = PackingSolver()
