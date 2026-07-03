from fastapi import HTTPException

from core.utils import (
    new_id,
    now_iso,
)

from repositories.notification_repository import (
    notification_repository,
)


class NotificationService:

    # =====================================================
    # CREATE
    # =====================================================

    async def create_notification(

        self,

        body,

    ):

        document = {

            "id": new_id(),

            "company_id": body.company_id,

            "user_id": body.user_id,

            "site_id": body.site_id,

            "labour_id": body.labour_id,

            "title": body.title,

            "message": body.message,

            "type": body.type,

            "priority": body.priority,

            "action_url": body.action_url,

            "read": False,

            "created_at": now_iso(),

        }

        await notification_repository.create(

            document

        )

        return document

    # =====================================================
    # LIST
    # =====================================================

    async def list_notifications(

        self,

        user,

    ):

        return await notification_repository.user_notifications(

            user["company_id"],

            user.get("id"),

        )

    # =====================================================
    # UNREAD COUNT
    # =====================================================

    async def unread_count(

        self,

        user,

    ):

        total = await notification_repository.unread_count(

            user["company_id"],

            user.get("id"),

        )

        return {

            "unread": total

        }

    # =====================================================
    # MARK READ
    # =====================================================

    async def mark_read(

        self,

        notification_id,

        user,

    ):

        result = await notification_repository.mark_read(

            notification_id,

            user["company_id"],

        )

        if result.matched_count == 0:

            raise HTTPException(

                status_code=404,

                detail="Notification not found",

            )

        return {

            "success": True

        }

    # =====================================================
    # MARK ALL READ
    # =====================================================

    async def mark_all_read(

        self,

        user,

    ):

        await notification_repository.mark_all_read(

            user["company_id"],

            user.get("id"),

        )

        return {

            "success": True

        }

    # =====================================================
    # DELETE
    # =====================================================

    async def delete_notification(

        self,

        notification_id,

        user,

    ):

        result = await notification_repository.delete(

            notification_id,

            user["company_id"],

        )

        if result.deleted_count == 0:

            raise HTTPException(

                status_code=404,

                detail="Notification not found",

            )

        return {

            "success": True

        }

    # =====================================================
    # ATTENDANCE EVENT
    # =====================================================

    async def notify_attendance(

        self,

        company_id,

        site_id,

        marked_by,

        total_labours,

    ):

        document = {

            "id": new_id(),

            "company_id": company_id,

            "user_id": None,

            "site_id": site_id,

            "labour_id": None,

            "title": "Attendance Submitted",

            "message": f"{total_labours} labours attendance marked.",

            "type": "ATTENDANCE",

            "priority": "LOW",

            "action_url": f"/attendance/{site_id}",

            "read": False,

            "created_at": now_iso(),

        }

        await notification_repository.create(

            document

        )

    # =====================================================
    # PAYMENT EVENT
    # =====================================================

    async def notify_payment(

        self,

        company_id,

        site_id,

        amount,

    ):

        document = {

            "id": new_id(),

            "company_id": company_id,

            "user_id": None,

            "site_id": site_id,

            "labour_id": None,

            "title": "Payment Received",

            "message": f"₹{amount:,.2f} payment received.",

            "type": "PAYMENT",

            "priority": "MEDIUM",

            "action_url": f"/payments/{site_id}",

            "read": False,

            "created_at": now_iso(),

        }

        await notification_repository.create(

            document

        )

    # =====================================================
    # LOW STOCK EVENT
    # =====================================================

    async def notify_low_stock(

        self,

        company_id,

        material,

        stock,

    ):

        document = {

            "id": new_id(),

            "company_id": company_id,

            "user_id": None,

            "site_id": material.get("site_id"),

            "labour_id": None,

            "title": "Low Stock Alert",

            "message": f"{material['name']} stock is only {stock} {material.get('unit','')}.",

            "type": "MATERIAL",

            "priority": "HIGH",

            "action_url": "/materials",

            "read": False,

            "created_at": now_iso(),

        }

        await notification_repository.create(

            document

        )

    # =====================================================
    # SITE ASSIGNED EVENT
    # =====================================================

    async def notify_site_assigned(

        self,

        company_id,

        user_id,

        site_name,

    ):

        document = {

            "id": new_id(),

            "company_id": company_id,

            "user_id": user_id,

            "site_id": None,

            "labour_id": None,

            "title": "New Site Assigned",

            "message": f"You have been assigned to {site_name}.",

            "type": "SITE",

            "priority": "MEDIUM",

            "action_url": "/sites",

            "read": False,

            "created_at": now_iso(),

        }

        await notification_repository.create(

            document
        )


notification_service = NotificationService()