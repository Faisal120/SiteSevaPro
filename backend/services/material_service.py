from fastapi import HTTPException

from services.notification_service import (
    notification_service,
)
from repositories.material_repository import material_repository

from core import new_id, now_iso
from services.access_control import require_site_access


class MaterialService:

    async def list_materials(
        self,
        site_id,
        user,
    ):

        query = {"company_id": user["company_id"]}

        if user["role"] == "CONTRACTOR":

            pass

        elif user["role"] == "SUPERVISOR":

            query["site_id"] = {
                "$in": user.get(
                    "site_ids",
                    []
                )
            }

        else:

            raise HTTPException(
                403,
                "Forbidden",
            )

        if site_id:

            await require_site_access(site_id, user)

            query["site_id"] = site_id

        return await material_repository.list(
            query
        )


    async def create_material(
        self,
        body,
        user,
    ):

        await require_site_access(body.site_id, user, write=True)

        document = {

            "id": new_id(),

            "company_id": user["company_id"],

            "created_at": now_iso(),

            **body.model_dump(),

        }

        await material_repository.create(
            document
        )

        return document

    async def _update_stock(

        self,

        material,

        body,

    ):

        delta = (

            body.quantity

            if body.type == "INWARD"

            else -body.quantity

        )

        new_stock = (

            material.get("stock", 0)

            + delta

        )

        if new_stock < 0:
            raise HTTPException(
                status_code=400,
                detail="Insufficient stock for this outward transaction",
            )

        await material_repository.update_stock(

            material["id"],

            material["company_id"],

            new_stock,

        )

        return new_stock
    
    
    async def _create_transaction(

    self,

    body,

    user,

):

        transaction = {

            "id": new_id(),

            "company_id": user["company_id"],

            "created_by": user["id"],

            "created_at": now_iso(),

            **body.model_dump(),

        }

        await material_repository.create_transaction(

            transaction

        )

        return transaction
    
    async def _create_low_stock_notification(

    self,

    material,

    stock,

    user,

):

        if stock >= material.get(

            "low_stock_threshold",

            10,

        ):

            return

        await material_repository.create_notification(

            {

                "id": new_id(),

                "company_id": user["company_id"],

                "title": "Low stock alert",

                "body": f"{material['name']} is low ({stock} {material.get('unit','')})",

                "type": "STOCK",

                "read": False,

                "created_at": now_iso(),

            }

        )
        
    async def _create_material_payment(

    self,

    body,

    material,

    user,

):

        if body.type != "INWARD":

            return

        if not body.rate:

            return

        await material_repository.create_payment(

            {

                "id": new_id(),

                "company_id": user["company_id"],

                "site_id": body.site_id,

                "type": "MATERIAL",

                "amount": body.quantity * body.rate,

                "description": f"{material['name']} from {body.vendor or 'Vendor'}",

                "party": body.vendor,

                "invoice_url": body.invoice_url,

                "date": now_iso()[:10],

                "created_at": now_iso(),

            }

        )
        
        
    async def create_material_transaction(

        self,

        body,

        user,

    ):

        await require_site_access(body.site_id, user, write=True)

        material = await material_repository.get(

            body.material_id,

            user["company_id"],

        )

        if not material:

            raise HTTPException(

                404,

                "Material not found",

            )

        if material.get("site_id") != body.site_id:
            raise HTTPException(
                status_code=400,
                detail="Material does not belong to the selected site",
            )

        stock = await self._update_stock(

            material,

            body,

        )

        transaction = await self._create_transaction(

            body,

            user,

        )

        await self._create_low_stock_notification(

            material,

            stock,

            user,

        )
        
        

        await self._create_material_payment(

            body,

            material,

            user,

        )

        return transaction
    

    # ======================================================
    # LIST MATERIAL TRANSACTIONS
    # ======================================================

    async def list_transactions(

        self,

        site_id,

        user,

    ):

        query = {"company_id": user["company_id"]}

        if site_id:

            await require_site_access(site_id, user)

            query["site_id"] = site_id

        return await material_repository.list_transactions(

            query

        )

material_service = MaterialService()
