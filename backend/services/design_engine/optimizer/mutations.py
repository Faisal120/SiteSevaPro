"""
Layout Mutations

Creates small random modifications
to a layout.
"""

import copy
import random


class LayoutMutation:

    # ------------------------------------------------

    def mutate(self, rooms):

        rooms = copy.deepcopy(rooms)

        if len(rooms) < 2:
            return rooms

        mutation = random.randint(1, 4)

        if mutation == 1:
            self.swap_rooms(rooms)

        elif mutation == 2:
            self.move_room(rooms)

        elif mutation == 3:
            self.resize_room(rooms)

        else:
            self.rotate_rooms(rooms)

        return rooms

    # ------------------------------------------------

    def swap_rooms(self, rooms):

        a, b = random.sample(range(len(rooms)), 2)

        rooms[a].x, rooms[b].x = rooms[b].x, rooms[a].x
        rooms[a].y, rooms[b].y = rooms[b].y, rooms[a].y

    # ------------------------------------------------

    def move_room(self, rooms):

        room = random.choice(rooms)

        room.x += random.uniform(-2, 2)
        room.y += random.uniform(-2, 2)

    # ------------------------------------------------

    def resize_room(self, rooms):

        room = random.choice(rooms)

        room.width += random.uniform(-1, 1)
        room.length += random.uniform(-1, 1)

        room.width = max(room.width, 5)
        room.length = max(room.length, 5)

    # ------------------------------------------------

    def rotate_rooms(self, rooms):

        room = random.choice(rooms)

        room.width, room.length = room.length, room.width


layout_mutation = LayoutMutation()