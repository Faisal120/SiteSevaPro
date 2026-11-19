import asyncio

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
            sites = await site_repository.get_by_company(
                user["company_id"]
            )

        elif role == "SUPERVISOR":
            sites = await site_repository.get_for_supervisor(
                company_id=user["company_id"],
                supervisor_id=user["id"],
                legacy_site_ids=user.get("site_ids", []),
            )

        elif role == "CLIENT":
            sites = await site_repository.get_for_client(
                company_id=user["company_id"],
                client_id=user["id"],
                client_email=user.get("email"),
                legacy_site_ids=user.get("site_ids", []),
            )

        else:
            raise HTTPException(
                status_code=403,
                detail="Forbidden",
            )

        return await self._hydrate_sites(sites, user["company_id"])

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
            return (await self._hydrate_sites([site], user["company_id"]))[0]

        if role in ("SUPERVISOR", "CLIENT"):
            if not self._has_site_access(site, user):
                raise HTTPException(
                    status_code=403,
                    detail="You are not assigned to this site.",
                )
            return (await self._hydrate_sites([site], user["company_id"]))[0]

        raise HTTPException(status_code=403, detail="Forbidden")

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

        supervisors = await self._load_supervisors(body, user)
        client = await self._load_client(body, user)
        payload = body.model_dump(exclude_unset=True)
        supervisor_ids = [supervisor["id"] for supervisor in supervisors]
        previous_assignees = set(site.get("supervisor_ids", []))
        if site.get("supervisor_id"):
            previous_assignees.add(site["supervisor_id"])
        previous_assignees.update(site.get("client_ids", []))
        if site.get("client_id"):
            previous_assignees.add(site["client_id"])
        current_assignees = set(supervisor_ids)
        if client:
            current_assignees.add(client["id"])

        payload.update({
            "supervisor_ids": supervisor_ids,
            "supervisor_names": [supervisor["full_name"] for supervisor in supervisors],
            "client_id": client["id"] if client else None,
            "client_ids": [client["id"]] if client else [],
            "client_name": client["full_name"] if client else None,
            "client_email": client["email"] if client else None,
        })

        payload["updated_at"] = now_iso()

        await site_repository.update(
            site_id=site_id,
            company_id=user["company_id"],
            payload=payload,
        )

        for user_id in previous_assignees - current_assignees:
            await site_repository.remove_site_from_user(user_id, site_id)
        await self._assign_users(site_id, supervisors, client)

        updated = await site_repository.get(
            site_id=site_id,
            company_id=user["company_id"],
        )
        return (await self._hydrate_sites([updated], user["company_id"]))[0]

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

        found_ids = {supervisor["id"] for supervisor in supervisors}
        missing_ids = set(supervisor_ids) - found_ids
        if missing_ids:
            raise HTTPException(422, "One or more supervisors are not in this company.")

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

        client = await site_repository.get_client(
            user["company_id"],
            client_id,
        )
        if not client:
            raise HTTPException(422, "The selected client is not in this company.")
        return client

    def _has_site_access(self, site: dict, user: dict) -> bool:
        user_id = user["id"]
        if user["role"] == "SUPERVISOR":
            assigned = set(site.get("supervisor_ids") or [])
            if site.get("supervisor_id"):
                assigned.add(site["supervisor_id"])
            if assigned:
                return user_id in assigned
            has_assignment_fields = any(
                key in site for key in ("supervisor_ids", "supervisor_id")
            )
        else:
            assigned = set(site.get("client_ids") or [])
            if site.get("client_id"):
                assigned.add(site["client_id"])
            if user_id in assigned:
                return True
            if str(site.get("client_email") or "").lower() == str(user.get("email") or "").lower():
                return True
            has_assignment_fields = any(
                key in site for key in ("client_ids", "client_id", "client_email")
            )
        return not has_assignment_fields and site["id"] in user.get("site_ids", [])

    async def _hydrate_sites(self, sites: list[dict], company_id: str) -> list[dict]:
        if not sites:
            return []
        user_ids = set()
        client_emails = set()
        for site in sites:
            user_ids.update(site.get("supervisor_ids") or [])
            if site.get("supervisor_id"):
                user_ids.add(site["supervisor_id"])
            user_ids.update(site.get("client_ids") or [])
            if site.get("client_id"):
                user_ids.add(site["client_id"])
            if site.get("client_email"):
                client_emails.add(site["client_email"].lower())
        users = await site_repository.get_users_by_ids(company_id, list(user_ids))
        users_by_id = {user["id"]: user for user in users}
        missing_emails = [
            email for email in client_emails
            if not any(user.get("email", "").lower() == email for user in users)
        ]
        email_users = await asyncio.gather(*[
            site_repository.get_user_by_email(company_id, email)
            for email in missing_emails
        ])
        users_by_email = {
            user["email"].lower(): user
            for user in (*users, *email_users)
            if user
        }
        return [
            self._hydrate_site(site, users_by_id, users_by_email)
            for site in sites
        ]

    def _hydrate_site(self, site: dict, users_by_id: dict, users_by_email: dict) -> dict:
        result = dict(site)
        supervisor_ids = list(dict.fromkeys([
            *(site.get("supervisor_ids") or []),
            *([site["supervisor_id"]] if site.get("supervisor_id") else []),
        ]))
        supervisor_names = [
            users_by_id[user_id].get("full_name") or users_by_id[user_id].get("email")
            for user_id in supervisor_ids
            if users_by_id.get(user_id)
        ] or list(site.get("supervisor_names") or [])
        client_ids = list(dict.fromkeys([
            *(site.get("client_ids") or []),
            *([site["client_id"]] if site.get("client_id") else []),
        ]))
        client = users_by_id.get(client_ids[0]) if client_ids else None
        if not client and site.get("client_email"):
            client = users_by_email.get(site["client_email"].lower())
        result.update({
            "supervisor_ids": supervisor_ids,
            "supervisor_names": supervisor_names,
            "client_ids": client_ids,
            "client_id": client_ids[0] if client_ids else None,
            "client_name": (client or {}).get("full_name") or site.get("client_name"),
            "client_email": (client or {}).get("email") or site.get("client_email"),
        })
        return result
        
        
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
