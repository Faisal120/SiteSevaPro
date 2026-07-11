class StatsBuilder:

    @staticmethod
    def build(
        dashboard: dict,
    ):

        stats = dashboard["stats"]

        return {

            "total_sites":

                stats.get(
                    "total_sites",
                    0,
                ),

            "active_sites":

                stats.get(
                    "active_sites",
                    0,
                ),

            "completed_sites":

                stats.get(
                    "completed_sites",
                    0,
                ),

            "labours":

                stats.get(
                    "labours",
                    0,
                ),

            "today_labours":

                stats.get(
                    "today_labours",
                    0,
                ),

            "pending_tasks":

                stats.get(
                    "pending_tasks",
                    0,
                ),

            "completed_tasks":

                stats.get(
                    "completed_tasks",
                    0,
                ),

            "today_reports":

                stats.get(
                    "today_reports",
                    0,
                ),

            "cashflow":

                stats.get(
                    "cashflow",
                    0,
                ),

            "expense":

                stats.get(
                    "expense",
                    0,
                ),

            "pending_payments":

                stats.get(
                    "pending_payments",
                    0,
                ),

            "net_profit":

                stats.get(
                    "net_profit",
                    0,
                ),

            "total_budget":

                stats.get(
                    "total_budget",
                    0,
                ),

            "low_stock":

                stats.get(
                    "low_stock",
                    0,
                ),

            "productivity":

                stats.get(
                    "productivity",
                    0,
                ),

        }