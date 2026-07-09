from datetime import datetime

from core import db


class AuditRepository:

    async def log(
        self,
        action,
        description,
    ):

        document = {

            "action": action,

            "description": description,

            "created_at": datetime.utcnow().isoformat(),

        }

        await db.audit_logs.insert_one(
            document.copy()
        )


audit_repository = AuditRepository()