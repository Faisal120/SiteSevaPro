"""
Room Score

Higher is better.
"""

class RoomScore:

    def score(

        self,

        room,

    ):

        score = 0

        area = room.width * room.length

        score += area

        if room.name == "Living":

            score += 150

        elif room.name == "Kitchen":

            score += 120

        elif room.name == "Bedroom":

            score += 100

        elif room.name == "Bathroom":

            score += 60

        return score


room_score = RoomScore()