class AlertsBuilder:

    @staticmethod
    def contractor(stats, dashboard):

        alerts = []

        if stats["pending_tasks"]:

            alerts.append({

                "type": "TASK",

                "severity": "HIGH",

                "title": f"{stats['pending_tasks']} Pending Tasks",

            })

        if stats["pending_payments"]:

            alerts.append({

                "type": "PAYMENT",

                "severity": "MEDIUM",

                "title": "Pending Client Payments",

            })

        if stats["low_stock"]:

            alerts.append({

                "type": "MATERIAL",

                "severity": "HIGH",

                "title": f"{stats['low_stock']} Low Stock Materials",

            })

        if stats["total_sites"] == 0:

            alerts.append({

                "type": "SITE",

                "severity": "LOW",

                "title": "Create your first Site",

            })

        if len(dashboard["team"]) == 0:

            alerts.append({

                "type": "TEAM",

                "severity": "LOW",

                "title": "No Team Members",

            })

        return alerts

    @staticmethod
    def supervisor(stats):

        alerts = []

        if stats["pending_tasks"]:

            alerts.append({

                "type": "TASK",

                "severity": "HIGH",

                "title": f"{stats['pending_tasks']} Pending Tasks",

            })

        if stats["todays_reports"] == 0:

            alerts.append({

                "type": "REPORT",

                "severity": "MEDIUM",

                "title": "No Daily Report Submitted Today",

            })

        if stats["active_sites"] == 0:

            alerts.append({

                "type": "SITE",

                "severity": "LOW",

                "title": "No Active Site Assigned",

            })

        return alerts

    @staticmethod
    def client(stats):

        alerts = []

        if stats["active_sites"] == 0:

            alerts.append({

                "type": "SITE",

                "severity": "LOW",

                "title": "No Active Project Assigned",

            })

        if stats["completed_sites"]:

            alerts.append({

                "type": "PROJECT",

                "severity": "LOW",

                "title": "Project Completed",

            })

        return alerts