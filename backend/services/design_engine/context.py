class DesignContext:

    def __init__(self):

        self.body = None

        self.plot = None

        self.rooms = []
        self.walls = []
        self.doors = []
        self.windows = []
        self.furniture = []
        self.corridors = []
        self.stairs = []

        self.parking = None
        self.garden = None

        self.graph = None
        self.graph_json = {}

        self.score = 0
        self.errors = []

        self.svg = ""

        self.schedules = []
        self.drawings = []
        self.exports = {}

        self.metadata = {}

        self.project = None

        self.response = {}