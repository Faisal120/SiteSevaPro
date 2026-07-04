from core import db


class NotificationRepository:

    # =====================================================
    # CREATE
    # =====================================================

    async def create(
        self,
        document: dict,
    ):

        await db.notifications.insert_one(
            document
        )

        return document


    # =====================================================
    # USER NOTIFICATIONS
    # =====================================================

    async def user_notifications(
        self,
        company_id: str,
        user_id: str | None,
    ):

        query = {
            "company_id": company_id
        }

        if user_id:

            query["$or"] = [

                {
                    "user_id": user_id
                },

                {
                    "user_id": None
                }

            ]

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
        company_id: str,
    ):

        return await db.notifications.update_one(

            {
                "id": notification_id,
                "company_id": company_id,
            },

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
        company_id: str,
        user_id: str | None,
    ):

        query = {
            "company_id": company_id
        }

        if user_id:

            query["$or"] = [

                {
                    "user_id": user_id
                },

                {
                    "user_id": None
                }

            ]

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
        company_id: str,
    ):

        return await db.notifications.delete_one(

            {
                "id": notification_id,
                "company_id": company_id,
            }

        )


    # =====================================================
    # UNREAD COUNT
    # =====================================================

    async def unread_count(
        self,
        company_id: str,
        user_id: str | None,
    ):

        query = {

            "company_id": company_id,

            "read": False,

        }

        if user_id:

            query["$or"] = [

                {
                    "user_id": user_id
                },

                {
                    "user_id": None
                }

            ]

        return await db.notifications.count_documents(
            query
        )


notification_repository = NotificationRepository()