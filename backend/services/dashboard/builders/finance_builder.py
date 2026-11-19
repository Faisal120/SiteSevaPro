"""Canonical finance aggregation for the contractor dashboard."""


class FinanceBuilder:
    """Derives finance totals from persisted payment and site records only."""

    _income_types = {"CLIENT_RECEIVED"}
    _expense_types = {"LABOUR", "MATERIAL", "EXPENSE"}

    @classmethod
    def payment_type(cls, payment: dict) -> str:
        return str(
            payment.get("type") or payment.get("payment_type") or ""
        ).strip().upper()

    @classmethod
    def is_expense_type(cls, payment_type: str) -> bool:
        return payment_type in cls._expense_types

    @staticmethod
    def payment_amount(payment: dict) -> float:
        try:
            return float(payment.get("amount") or 0)
        except (TypeError, ValueError):
            return 0.0

    @staticmethod
    def _site_budget(site: dict) -> float:
        try:
            return float(site.get("budget") or 0)
        except (TypeError, ValueError):
            return 0.0

    @classmethod
    def build(cls, payments: list[dict], sites: list[dict]) -> dict:
        revenue = 0.0
        labour_expense = 0.0
        material_expense = 0.0
        other_expense = 0.0

        for payment in payments:
            amount = cls.payment_amount(payment)
            payment_type = cls.payment_type(payment)
            if payment_type in cls._income_types:
                revenue += amount
            elif payment_type == "LABOUR":
                labour_expense += amount
            elif payment_type == "MATERIAL":
                material_expense += amount
            elif payment_type == "EXPENSE":
                other_expense += amount

        expense = labour_expense + material_expense + other_expense
        net_profit = revenue - expense
        total_budget = sum(cls._site_budget(site) for site in sites)

        return {
            "total_revenue": revenue,
            "expense": expense,
            "labour_expense": labour_expense,
            "material_expense": material_expense,
            "other_expense": other_expense,
            "net_profit": net_profit,
            "net_loss": abs(net_profit) if net_profit < 0 else 0.0,
            "cashflow": net_profit,
            "pending_payments": max(total_budget - revenue, 0.0),
            "total_budget": total_budget,
        }
