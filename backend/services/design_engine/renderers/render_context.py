from dataclasses import dataclass, field


@dataclass
class RenderContext:

    width: int = 0

    height: int = 0

    scale: float = 1.0

    margin: int = 40

    elements: list = field(default_factory=list)

    defs: list = field(default_factory=list)