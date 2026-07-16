from datetime import datetime


class TitleBlockRenderer:

    def render(

        self,

        sheet,

        project,

    ):

        sheet.title_block = {

            "company":project.company,

            "project":project.project_name,

            "client":project.client_name,

            "architect":project.architect,

            "location":project.location,

            "date":datetime.now().strftime("%d-%m-%Y"),

            "revision":project.revision,

            "sheet":sheet.number,

        }

        return sheet


title_block_renderer = TitleBlockRenderer()