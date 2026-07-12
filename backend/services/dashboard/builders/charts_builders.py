class ChartsBuilder:

    @staticmethod
    def build(data):

        site_progress = []

        expense_breakdown = {}

        attendance = []

        cashflow = {}

        for site in data.get("sites", []):

            site_progress.append(

                {

                    "name": site.get("name"),

                    "progress": site.get(
                        "progress",
                        0,
                    ),

                }

            )

        for material in data.get("materials", []):

            category = material.get(
                "category",
                "Others",
            )

            expense_breakdown.setdefault(
                category,
                0,
            )

            expense_breakdown[category] += material.get(
                "total_cost",
                material.get(
                    "amount",
                    0,
                ),
            )

        for payment in data.get("payments", []):

            created = payment.get(
                "created_at"
            )

            if not created:

                continue

            month = str(created)[:7]

            cashflow.setdefault(

                month,

                {

                    "income": 0,

                    "expense": 0,

                },

            )

            if payment.get("payment_type") == "CLIENT_RECEIVED":

                cashflow[month]["income"] += payment.get(
                    "amount",
                    0,
                )

            else:

                cashflow[month]["expense"] += payment.get(
                    "amount",
                    0,
                )

        for row in data.get("attendance", []):

            attendance.append(

                {

                    "date": row.get("_id"),

                    "present": row.get(
                        "present",
                        0,
                    ),

                    "absent": row.get(
                        "absent",
                        0,
                    ),

                }

            )

        return {

            "site_progress": site_progress,

            "expense_breakdown": [

                {

                    "name": k,

                    "value": v,

                }

                for k, v in expense_breakdown.items()

            ],

            "attendance": attendance,

            "cashflow": [

                {

                    "month": k,

                    **v,

                }

                for k, v in cashflow.items()

            ],

        }