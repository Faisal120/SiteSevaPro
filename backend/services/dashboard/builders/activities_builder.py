class ActivitiesBuilder:

    @staticmethod
    def contractor(data):

        activities = []

        for payment in data.get("payments", []):

            activities.append({

                "id": payment.get("id"),

                "type": "PAYMENT",

                "title": payment.get(
                    "payment_type"
                ),

                "description": f"₹ {payment.get('amount',0):,.0f}",

                "created_at": payment.get(
                    "created_at"
                ),

            })

        for report in data.get("reports", []):

            activities.append({

                "id": report.get("id"),

                "type": "REPORT",

                "title": report.get(
                    "site_name"
                ),

                "description": report.get(
                    "description",
                    "",
                ),

                "created_at": report.get(
                    "created_at"
                ),

            })

        activities.sort(

            key=lambda x: x.get(
                "created_at"
            ),

            reverse=True,

        )

        return activities[:20]

    @staticmethod
    def reports_only(reports):

        activities = []

        for report in reports:

            activities.append({

                "id": report.get("id"),

                "type": "REPORT",

                "title": report.get(
                    "site_name",
                    "Daily Report",
                ),

                "description": report.get(
                    "description",
                    "",
                ),

                "created_at": report.get(
                    "created_at"
                ),

            })

        activities.sort(

            key=lambda x: x.get(
                "created_at"
            ),

            reverse=True,

        )

        return activities[:20]