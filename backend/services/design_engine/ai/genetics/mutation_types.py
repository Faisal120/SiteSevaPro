from enum import Enum


class MutationType(str, Enum):

    SWAP = "SWAP"

    SHIFT = "SHIFT"

    ROTATE = "ROTATE"

    ZONE = "ZONE"

    PACKING = "PACKING"