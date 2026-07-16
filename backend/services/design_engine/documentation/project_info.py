from dataclasses import dataclass


@dataclass
class ProjectInfo:

    project_name: str

    client_name: str

    architect: str

    location: str

    drawing_date: str

    revision: str = "A"

    company="SiteSeva Pro"