from dataclasses import dataclass, field


@dataclass
class DrawingSheet:

    number: str

    title: str

    scale: str

    size: str

    svg: str = ""

    tables: list = field(default_factory=list)

    legends: list = field(default_factory=list)