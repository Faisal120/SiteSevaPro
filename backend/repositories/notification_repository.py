from core import db
from services.notification_delivery import notification_delivery


class NotificationRepository:

    @staticmethod
    def _user_scope(
        company_id: str | None,
        user_id: str | None,
    ) -> dict:
        # Platform administrators do not belong to a tenant.  Keep their
        # notifications strictly user-scoped instead of querying every company.
        if company_id is None:
            return {"user_id": user_id} if user_id else {"user_id": "__none__"}

        query = {"company_id": company_id}
        if user_id:
            query["$or"] = [
                {"user_id": user_id},
                {"user_id": None},
            ]
        return query

    # =====================================================
    # CREATE
    # =====================================================

    async def create(
        self,
        document: dict,
    ):

        db_document = document.copy()

        await db.notifications.insert_one(db_document)

        await notification_delivery.deliver(document)

        return document

    async def register_device(self, document: dict):
        return await db.push_devices.update_one(
            {"token": document["token"]},
            {"$set": document},
            upsert=True,
        )

    async def unregister_device(self, token: str, user_id: str):
        return await db.push_devices.delete_one(
            {"token": token, "user_id": user_id}
        )


    # =====================================================
    # USER NOTIFICATIONS
    # =====================================================

    async def user_notifications(
        self,
        company_id: str | None,
        user_id: str | None,
    ):

        query = self._user_scope(company_id, user_id)

        return await (

            db.notifications

            .find(
                query,
                {
                    "_id": 0
                }
            )

            .sort(
                "created_at",
                -1
            )

            .limit(200)

            .to_list(200)

        )


    # =====================================================
    # MARK READ
    # =====================================================

    async def mark_read(
        self,
        notification_id: str,
        company_id: str | None,
        user_id: str | None,
    ):

        return await db.notifications.update_one(

            {"id": notification_id, **self._user_scope(company_id, user_id)},

            {
                "$set": {
                    "read": True
                }
            }

        )


    # =====================================================
    # MARK ALL READ
    # =====================================================

    async def mark_all_read(
        self,
        company_id: str | None,
        user_id: str | None,
    ):

        query = self._user_scope(company_id, user_id)

        return await db.notifications.update_many(

            query,

            {
                "$set": {
                    "read": True
                }
            }

        )


    # =====================================================
    # DELETE
    # =====================================================

    async def delete(
        self,
        notification_id: str,
        company_id: str | None,
        user_id: str | None,
    ):

        return await db.notifications.delete_one(

            {"id": notification_id, **self._user_scope(company_id, user_id)}

        )


    # =====================================================
    # UNREAD COUNT
    # =====================================================

    async def unread_count(
        self,
        company_id: str | None,
        user_id: str | None,
    ):

        query = {
            **self._user_scope(company_id, user_id),
            "read": False,
        }

        return await db.notifications.count_documents(
            query
        )


notification_repository = NotificationRepository()
