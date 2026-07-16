from dataclasses import dataclass
from typing import Any


@dataclass
class LayoutCandidate:

    id: int

    rooms: list

    score: float = 0.0

    graph: Any = None

    metadata: dict = None

    def __post_init__(self):

        if self.metadata is None:

            self.metadata = {}