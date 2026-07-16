class RelationshipEngine:

    def solve(

        self,

        furniture,

    ):

        for item in furniture:

            if item.metadata.get("faces") == "TV":

                ...

            if item.metadata.get("center_of") == "SOFA":

                ...

        return furniture