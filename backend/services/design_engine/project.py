from dataclasses import dataclass

@dataclass
class Project:
    company: str = ""
    project_name: str = ""
    client_name: str = ""
    architect: str = ""
    location: str = ""
    revision: str = "R0"