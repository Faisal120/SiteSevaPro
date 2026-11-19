class StatsBuilder:

    @staticmethod
    def build(
        dashboard: dict,
    ):

        return {

            "total_sites":

                dashboard.get(
                    "total_sites",
                    0,
                ),

            "active_sites":

                dashboard.get(
                    "active_sites",
                    0,
                ),

            "completed_sites":

                dashboard.get(
                    "completed_sites",
                    0,
                ),

            "labours":

                dashboard.get(
                    "total_labours",
                    0,
                ),

            "today_labours":

                dashboard.get(
                    "todays_labours",
                    0,
                ),

            "pending_tasks":

                dashboard.get(
                    "pending_tasks",
                    0,
                ),

            "completed_tasks":

                dashboard.get(
                    "completed_tasks",
                    0,
                ),

            "today_reports":

                dashboard.get(
                    "todays_reports",
                    0,
                ),

            "cashflow":

                dashboard.get(
                    "cashflow",
                    0,
                ),

            "total_revenue":

                dashboard.get(
                    "total_revenue",
                    0,
                ),

            "expense":

                dashboard.get(
                    "expense",
                    0,
                ),

            "pending_payments":

                dashboard.get(
                    "pending_payments",
                    0,
                ),

            "net_profit":

                dashboard.get(
                    "net_profit",
                    0,
                ),

            "net_loss":

                dashboard.get(
                    "net_loss",
                    0,
                ),

            "labour_expense":

                dashboard.get(
                    "labour_expense",
                    0,
                ),

            "material_expense":

                dashboard.get(
                    "material_expense",
                    0,
                ),

            "other_expense":

                dashboard.get(
                    "other_expense",
                    0,
                ),

            "total_budget":

                dashboard.get(
                    "total_budget",
                    0,
                ),

            "low_stock":

                dashboard.get(
                    "low_stock",
                    0,
                ),

            "productivity":

                dashboard.get(
                    "productivity",
                    0,
                ),

        }
