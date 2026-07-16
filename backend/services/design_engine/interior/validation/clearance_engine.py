CLEARANCES = {

    "BED":0.75,

    "WARDROBE":0.90,

    "SOFA":0.75,

    "DINING":1.20,

    "TOILET":0.75,

}

class ClearanceEngine:

    def apply(

    room,

    furniture,

):

        bed = None

        wardrobe = None

        study = None

        for item in furniture:

            if item.category == "BED":

                bed = item

            elif item.category == "WARDROBE":

                wardrobe = item

            elif item.category == "STUDY":

                study = item

        if bed:

            bed.metadata["headboard"] = True

            bed.metadata["preferred_wall"] = "TOP"

        if wardrobe:

            wardrobe.metadata["preferred_wall"] = "BOTTOM"

        if study:

            study.metadata["preferred_wall"] = "WINDOW"

        return furniture


clearance_engine = ClearanceEngine()