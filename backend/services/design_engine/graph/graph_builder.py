import uuid

from services.design_engine.graph.graph import (
    GeometryGraph,
    Node,
)


class GraphBuilder:

    def _room_type(self, room):
        return room.name.split("_")[0]

    def build(self, rooms):

        graph = GeometryGraph()
        nodes = []

        for room in rooms:

            node = Node(
                id=str(uuid.uuid4()),
                room_name=room.name,
                x=room.x,
                y=room.y,
                width=room.width,
                height=room.length,
                zone=room.preferred_zone or "",
            )

            room.graph_id = node.id

            graph.add_node(node)

            nodes.append((room, node))

        for i in range(len(nodes)):
            room_a, node_a = nodes[i]

            for j in range(i + 1, len(nodes)):
                room_b, node_b = nodes[j]

                type_a = self._room_type(room_a)
                type_b = self._room_type(room_b)

                should_connect = (
                    type_b in room_a.adjacent_to
                    or type_a in room_b.adjacent_to
                    or self._touching(room_a, room_b)
                )

                if should_connect:
                    graph.add_edge(node_a.id, node_b.id)
                    graph.add_edge(node_b.id, node_a.id)

        return graph

    def _touching(self, a, b):

        tol = 2.0

        horizontal = (
            abs((a.x + a.width) - b.x) <= tol
            or abs((b.x + b.width) - a.x) <= tol
        )

        vertical = (
            abs((a.y + a.length) - b.y) <= tol
            or abs((b.y + b.length) - a.y) <= tol
        )

        overlap_x = not (
            a.x + a.width <= b.x
            or b.x + b.width <= a.x
        )

        overlap_y = not (
            a.y + a.length <= b.y
            or b.y + b.length <= a.y
        )

        return (
            horizontal and overlap_y
        ) or (
            vertical and overlap_x
        )


graph_builder = GraphBuilder()