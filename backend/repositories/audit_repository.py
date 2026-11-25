from datetime import datetime

from core import db


class AuditRepository:

    async def log(
        self,
        action,
        description,
        *,
        actor_id: str | None = None,
        account_id: str | None = None,
        company_id: str | None = None,
        outcome: str | None = None,
    ):

        document = {

            "action": action,

            "description": description,

            "created_at": datetime.utcnow().isoformat(),
        }
        for key, value in {"actor_id": actor_id, "account_id": account_id, "company_id": company_id, "outcome": outcome}.items():
            if value is not None:
                document[key] = value

        await db.audit_logs.insert_one(
            document.copy()
        )


audit_repository = AuditRepository()
