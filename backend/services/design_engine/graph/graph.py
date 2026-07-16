"""
Geometry Graph

Every room becomes a Node.

Every adjacency becomes an Edge.
"""

from dataclasses import dataclass, field


@dataclass
class Edge:

    source: str

    target: str

    edge_type: str = "adjacent"

    weight: int = 1


@dataclass
class Node:

    id: str

    room_name: str

    x: float

    y: float

    width: float

    height: float

    floor: int = 1

    zone: str = ""

    edges: list[Edge] = field(default_factory=list)


class GeometryGraph:

    def __init__(self):

        self.nodes = {}

    # --------------------------------------------------

    def add_node(

        self,

        node: Node,

    ):

        self.nodes[node.id] = node

    # --------------------------------------------------

    def add_edge(

        self,

        source,

        target,

        edge_type="adjacent",

    ):

        edge = Edge(

            source,

            target,

            edge_type,

        )

        self.nodes[source].edges.append(edge)

    # --------------------------------------------------

    def get_node(

        self,

        node_id,

    ):

        return self.nodes.get(node_id)

    # --------------------------------------------------

    def all_nodes(

        self,

    ):

        return list(self.nodes.values())

    # --------------------------------------------------

    def neighbours(

        self,

        node_id,

    ):

        return [

            self.nodes[e.target]

            for e in self.nodes[node_id].edges

            if e.target in self.nodes

        ]