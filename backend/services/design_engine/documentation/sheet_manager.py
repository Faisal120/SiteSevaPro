class SheetManager:

    def __init__(self):

        self.sheets = []

    def add(

        self,

        sheet,

    ):

        self.sheets.append(sheet)

    def all(

        self,

    ):

        return self.sheets


sheet_manager = SheetManager()