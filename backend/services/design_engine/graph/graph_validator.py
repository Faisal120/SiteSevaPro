"""
Graph Validator

Checks if every room
is reachable.
"""

from collections import deque


class GraphValidator:

    def validate(

        self,

        graph,

    ):

        nodes = graph.all_nodes()

        if not nodes:

            return True

        visited = set()

        queue = deque()

        queue.append(nodes[0].id)

        while queue:

            node = queue.popleft()

            if node in visited:

                continue

            visited.add(node)

            for neighbour in graph.neighbours(node):

                queue.append(neighbour.id)

        return len(visited) == len(nodes)


graph_validator = GraphValidator()