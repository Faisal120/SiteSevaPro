from fastapi import HTTPException

from core import new_id, now_iso

from repositories.site_repository import site_repository

from services.notification_service import notification_service


class SiteService:

    # ============================================================
    # LIST SITES
    # ============================================================

    async def list_sites(
        self,
        user: dict,
    ):

        role = user["role"]

        if role == "CONTRACTOR":

            return await site_repository.get_by_company(
                user["company_id"]
            )

        elif role == "SUPERVISOR":

            return await site_repository.get_for_supervisor(
                company_id=user["company_id"],
                supervisor_id=user["id"],
            )

        elif role == "CLIENT":

            return await site_repository.get_for_client(
                company_id=user["company_id"],
                client_id=user["id"],
            )

        raise HTTPException(
            status_code=403,
            detail="Forbidden",
        )

    # ============================================================
    # CREATE SITE
    # ============================================================

    async def create_site(
        self,
        body,
        user,
    ):

        # --------------------------------------------------
        # Subscription Validation
        # --------------------------------------------------

        await self._validate_subscription(
            user
        )

        # --------------------------------------------------
        # Load Team
        # --------------------------------------------------

        supervisors = await self._load_supervisors(
            body,
            user,
        )

        client = await self._load_client(
            body,
            user,
        )

        # --------------------------------------------------
        # Build Site
        # --------------------------------------------------

        document = self._build_document(
            body=body,
            user=user,
            supervisors=supervisors,
            client=client,
        )

        # --------------------------------------------------
        # Save Site
        # --------------------------------------------------

        await site_repository.create(
            document
        )

        # --------------------------------------------------
        # Create Default Tasks
        # --------------------------------------------------

        task_documents = []

        for title, weight in self._generate_default_tasks(
            body
        ):

            task_documents.append(
                {
                    "id": new_id(),
                    "company_id": user["company_id"],
                    "site_id": document["id"],
                    "title": title,
                    "weight": weight,
                    "completed": False,
                    "created_at": now_iso(),
                }
            )

        await site_repository.bulk_create_tasks(
            task_documents
        )

        # --------------------------------------------------
        # Temporary Backward Compatibility
        # --------------------------------------------------

        await self._assign_users(
            document["id"],
            supervisors,
            client,
        )

        # --------------------------------------------------
        # Notifications
        # --------------------------------------------------

        try:

            if supervisors:

                await notification_service.notify_supervisors_site_assigned(
                    document,
                    supervisors,
                )

            if client:

                await notification_service.notify_client_site_assigned(
                    document,
                    client,
                )

        except Exception:

            pass

        return document

    # ============================================================
    # GET SITE
    # ============================================================

    async def get_site(
        self,
        site_id: str,
        user: dict,
    ):

        site = await site_repository.get(
            site_id=site_id,
            company_id=user["company_id"],
        )

        if not site:

            raise HTTPException(
                status_code=404,
                detail="Site not found",
            )

        role = user["role"]

        if role == "CONTRACTOR":

            return site

        if role == "SUPERVISOR":

            if user["id"] not in site.get(
                "supervisor_ids",
                [],
            ):

                raise HTTPException(
                    status_code=403,
                    detail="You are not assigned to this site.",
                )

            return site

        if role == "CLIENT":

            if user["id"] not in site.get(
                "client_ids",
                [],
            ):

                raise HTTPException(
                    status_code=403,
                    detail="You are not assigned to this site.",
                )

            return site

        raise HTTPException(
            status_code=403,
            detail="Forbidden",
        )

    # ============================================================
    # UPDATE SITE
    # ============================================================

    async def update_site(
        self,
        site_id: str,
        body,
        user,
    ):

        site = await site_repository.get(
            site_id=site_id,
            company_id=user["company_id"],
        )

        if not site:

            raise HTTPException(
                status_code=404,
                detail="Site not found",
            )

        payload = body.model_dump(
            exclude_unset=True
        )

        payload["updated_at"] = now_iso()

        await site_repository.update(
            site_id=site_id,
            company_id=user["company_id"],
            payload=payload,
        )

        return await site_repository.get(
            site_id=site_id,
            company_id=user["company_id"],
        )

    # ============================================================
    # DELETE SITE
    # ============================================================

    async def delete_site(
        self,
        site_id: str,
        user: dict,
    ):

        site = await site_repository.get(
            site_id=site_id,
            company_id=user["company_id"],
        )

        if not site:

            raise HTTPException(
                status_code=404,
                detail="Site not found",
            )

        await site_repository.delete(
            site_id=site_id,
            company_id=user["company_id"],
        )

        return {
            "success": True,
            "message": "Site deleted successfully",
        }
        
    # ============================================================
    # ASSIGN SUPERVISOR
    # ============================================================

    async def assign_supervisor(
        self,
        site_id: str,
        body,
        user,
    ):

        site = await site_repository.get(
            site_id=site_id,
            company_id=user["company_id"],
        )

        if not site:

            raise HTTPException(
                status_code=404,
                detail="Site not found",
            )

        supervisor = await site_repository.get_user_by_id(
            company_id=user["company_id"],
            user_id=body.user_id,
        )

        if not supervisor:

            raise HTTPException(
                status_code=404,
                detail="Supervisor not found",
            )

        supervisor_ids = list(
            site.get(
                "supervisor_ids",
                [],
            )
        )

        supervisor_names = list(
            site.get(
                "supervisor_names",
                [],
            )
        )

        if supervisor["id"] not in supervisor_ids:

            supervisor_ids.append(
                supervisor["id"]
            )

            supervisor_names.append(
                supervisor["full_name"]
            )

        await site_repository.update_supervisors(
            site_id=site_id,
            company_id=user["company_id"],
            supervisor_ids=supervisor_ids,
            supervisor_names=supervisor_names,
        )

        # Backward compatibility
        await site_repository.add_site_to_user(
            supervisor["id"],
            site_id,
        )

        try:

            await notification_service.notify_supervisors_site_assigned(
                site,
                [supervisor],
            )

        except Exception:

            pass

        return {
            "success": True,
            "message": "Supervisor assigned successfully",
        }

    # ============================================================
    # ASSIGN CLIENT
    # ============================================================

    async def assign_client(
        self,
        site_id: str,
        body,
        user,
    ):

        site = await site_repository.get(
            site_id=site_id,
            company_id=user["company_id"],
        )

        if not site:

            raise HTTPException(
                status_code=404,
                detail="Site not found",
            )

        client = await site_repository.get_user_by_id(
            company_id=user["company_id"],
            user_id=body.user_id,
        )

        if not client or client["role"] != "CLIENT":
            raise HTTPException(
                status_code=404,
                detail="Client not found",
            )

        client_ids = list(
            site.get(
                "client_ids",
                [],
            )
        )

        if client["id"] not in client_ids:

            client_ids.append(
                client["id"]
            )

        await site_repository.update_client(
            site_id=site_id,
            company_id=user["company_id"],
            client_id=client["id"],
            client_ids=client_ids,
            client_name=client["full_name"],
            client_email=client["email"],
        )

        # Backward compatibility
        await site_repository.add_site_to_user(
            client["id"],
            site_id,
        )

        try:

            await notification_service.notify_client_site_assigned(
                site,
                client,
            )

        except Exception:

            pass

        return {
            "success": True,
            "message": "Client assigned successfully",
        }

    # ============================================================
    # VALIDATE SUBSCRIPTION
    # ============================================================

    async def _validate_subscription(
        self,
        user: dict,
    ):

        subscription = await site_repository.active_subscription(
            user["company_id"]
        )

        plan = (
            subscription or {}
        ).get(
            "plan",
            "FREE",
        )

        if plan == "FREE":

            total_sites = await site_repository.company_site_count(
                user["company_id"]
            )

            if total_sites >= 1:

                raise HTTPException(
                    status_code=402,
                    detail="Free plan allows only one site. Upgrade your subscription.",
                )

        return plan

    # ============================================================
    # LOAD SUPERVISORS
    # ============================================================

    async def _load_supervisors(
        self,
        body,
        user,
    ):

        supervisor_ids = getattr(
            body,
            "supervisor_ids",
            [],
        )

        if not supervisor_ids:

            return []

        supervisors = await site_repository.get_supervisors(
            user["company_id"],
            supervisor_ids,
        )

        return supervisors

    # ============================================================
    # LOAD CLIENT
    # ============================================================

    async def _load_client(
        self,
        body,
        user,
    ):

        client_id = getattr(
            body,
            "client_id",
            None,
        )

        if not client_id:

            return None

        return await site_repository.get_client(
            user["company_id"],
            client_id,
        )
        
        
            # ============================================================
    # BUILD SITE DOCUMENT
    # ============================================================

    def _build_document(
        self,
        body,
        user,
        supervisors,
        client,
    ):

        data = body.model_dump(
            exclude_unset=True
        )

        supervisor_ids = [
            supervisor["id"]
            for supervisor in supervisors
        ]

        supervisor_names = [
            supervisor["full_name"]
            for supervisor in supervisors
        ]

        client_ids = []

        if client:
            client_ids.append(
                client["id"]
            )

        document = {

            # ----------------------------------------------------
            # Identity
            # ----------------------------------------------------

            "id": new_id(),

            # ----------------------------------------------------
            # Ownership
            # ----------------------------------------------------

            "company_id": user["company_id"],

            "contractor_id": user["id"],

            "created_by": user["id"],

            "owner_id": user["id"],

            # ----------------------------------------------------
            # Audit
            # ----------------------------------------------------

            "created_at": now_iso(),

            "updated_at": now_iso(),

            # ----------------------------------------------------
            # Site Details
            # ----------------------------------------------------

            **data,

            # ----------------------------------------------------
            # Supervisor
            # ----------------------------------------------------

            "supervisor_ids": supervisor_ids,

            "supervisor_names": supervisor_names,

            # ----------------------------------------------------
            # Client
            # ----------------------------------------------------

            "client_id": client["id"] if client else None,

            "client_ids": client_ids,

            "client_name": (
                client["full_name"]
                if client
                else None
            ),

            "client_email": (
                client["email"]
                if client
                else None
            ),

            # ----------------------------------------------------
            # Defaults
            # ----------------------------------------------------

            "status": "ACTIVE",

            "progress": 0,

            "completed_tasks": 0,

            "pending_tasks": 0,

            "labour_count": 0,

            "today_attendance": 0,

            "expense": 0,

            "material_cost": 0,

            "labour_cost": 0,

            "other_cost": 0,

            "total_cost": 0,

            "last_activity": now_iso(),

        }

        return document

    # ============================================================
    # ASSIGN USERS (Backward Compatibility)
    # ============================================================

    async def _assign_users(
        self,
        site_id: str,
        supervisors: list,
        client,
    ):

        # ----------------------------------------------------
        # NOTE:
        # users.site_ids is retained only for backward
        # compatibility. The source of truth is:
        #
        # sites.supervisor_ids
        # sites.client_ids
        # ----------------------------------------------------

        for supervisor in supervisors:

            await site_repository.add_site_to_user(
                supervisor["id"],
                site_id,
            )

        if client:

            await site_repository.add_site_to_user(
                client["id"],
                site_id,
            )

    # ============================================================
    # DEFAULT CONSTRUCTION TASKS
    # ============================================================

    def _generate_default_tasks(
        self,
        body,
    ):

        tasks = [

            ("Site Layout", 1),

            ("Excavation", 2),

            ("Earth Filling", 2),

        ]

        if getattr(
            body,
            "has_boring",
            False,
        ):

            tasks.append(
                ("Boring", 2)
            )

        if getattr(
            body,
            "has_septic_tank",
            False,
        ):

            tasks.append(
                ("Septic Tank", 2)
            )

        if getattr(
            body,
            "has_soak_pit",
            False,
        ):

            tasks.append(
                ("Soak Pit", 2)
            )

        tasks.extend([

            ("PCC", 3),

            ("Footing", 4),

            ("Plinth Beam", 4),

            ("Ground Floor Column", 4),

            ("Ground Floor Brickwork", 5),

            ("Ground Floor Slab", 6),

        ])

        floors = getattr(
            body,
            "floors",
            1,
        )

        if floors >= 2:

            tasks.extend([

                ("First Floor Column", 4),

                ("First Floor Brickwork", 5),

                ("First Floor Slab", 6),

            ])

        if floors >= 3:

            tasks.extend([

                ("Second Floor Column", 4),

                ("Second Floor Brickwork", 5),

                ("Second Floor Slab", 6),

            ])

        if floors >= 4:

            tasks.extend([

                ("Third Floor Column", 4),

                ("Third Floor Brickwork", 5),

                ("Third Floor Slab", 6),

            ])

        if getattr(
            body,
            "has_mumty",
            False,
        ):

            tasks.extend([

                ("Mumty Brickwork", 2),

                ("Mumty Slab", 2),

            ])

        tasks.extend([

            ("Electrical", 3),

            ("Plumbing", 3),

            ("Flooring", 3),

            ("Painting", 3),

            ("Final Cleaning", 2),

            ("Quality Inspection", 2),

            ("Project Handover", 1),

        ])

        return tasks


site_service = SiteService()