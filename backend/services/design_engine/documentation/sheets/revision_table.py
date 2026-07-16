from datetime import datetime


class RevisionTable:

    def create(self):

        return [

            {

                "rev":"A",

                "date":datetime.now().strftime("%d-%m-%Y"),

                "remarks":"Initial Issue",

            }

        ]


revision_table = RevisionTable()