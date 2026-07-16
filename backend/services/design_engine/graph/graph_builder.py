"""
Creates graph from layout.
"""

import uuid

from services.design_engine.graph.graph import (

    GeometryGraph,

    Node,

)


class GraphBuilder:

    # --------------------------------------------------

    def build(

        self,

        rooms,

    ):

        graph = GeometryGraph()

        mapping = {}

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

            graph.add_node(node)

            mapping[room] = node.id

        ids = list(mapping.values())

        room_list = list(mapping.keys())

        for i in range(len(room_list)):

            for j in range(i + 1, len(room_list)):

                if self._touching(

                    room_list[i],

                    room_list[j],

                ):

                    graph.add_edge(

                        ids[i],

                        ids[j],

                    )

                    graph.add_edge(

                        ids[j],

                        ids[i],

                    )

        return graph

    # --------------------------------------------------

    def _touching(

        self,

        a,

        b,

    ):

        tol = 0.5

        horizontal = (

            abs(

                (a.x + a.width)

                - b.x

            ) <= tol

            or

            abs(

                (b.x + b.width)

                - a.x

            ) <= tol

        )

        vertical = (

            abs(

                (a.y + a.length)

                - b.y

            ) <= tol

            or

            abs(

                (b.y + b.length)

                - a.y

            ) <= tol

        )

        overlap_x = not (

            a.x + a.width <= b.x

            or

            b.x + b.width <= a.x

        )

        overlap_y = not (

            a.y + a.length <= b.y

            or

            b.y + b.length <= a.y

        )

        return (

            horizontal

            and overlap_y

        ) or (

            vertical

            and overlap_x

        )


graph_builder = GraphBuilder()