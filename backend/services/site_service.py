from repositories.site_repository import site_repository

from services.notification_service import (
    notification_service,
)


class SiteService:

    async def list_sites(
        self,
        user: dict,
    ):

        query = {}

        if user["role"] == "CONTRACTOR":

            query["company_id"] = user["company_id"]

        elif user["role"] == "SUPERVISOR":

            query["id"] = {
                "$in": user.get(
                    "site_ids",
                    [],
                )
            }

        elif user["role"] == "CLIENT":

            query["id"] = {
                "$in": user.get(
                    "site_ids",
                    [],
                )
            }

        else:

            raise HTTPException(
                403,
                "Forbidden",
            )

        return await site_repository.list(query)

    async def create_site(
    self,
    body,
    user,
):

        # --------------------------------------------------
        # 1. Validate Subscription
        # --------------------------------------------------

        await self._validate_subscription(user)

        # --------------------------------------------------
        # 2. Load Users
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
        # 3. Build Site Document
        # --------------------------------------------------

        document = self._build_document(
            body,
            user,
            supervisors,
            client,
        )

        # --------------------------------------------------
        # 4. Save Site
        # --------------------------------------------------

        await site_repository.create(
            document
        )

        # --------------------------------------------------
        # 5. Generate Construction Tasks
        # --------------------------------------------------

        task_templates = self._generate_default_tasks(
            body
        )

        task_documents = []

        for title, weight in task_templates:

            task_documents.append(
                {
                    "id": new_id(),
                    "site_id": document["id"],
                    "company_id": user["company_id"],
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
        # 6. Assign Users
        # --------------------------------------------------

        await self._assign_users(
            document["id"],
            supervisors,
            client,
        )

        return document

    # ============================================================
# GET SITE
# ============================================================

    async def get_site(

        self,

        site_id: str,

        user: dict,

    ):

        site = await site_repository.get(site_id)

        if not site:

            raise HTTPException(
                404,
                "Site not found",
            )

        # Contractor

        if (

            user["role"] == "CONTRACTOR"

            and

            site["company_id"] != user["company_id"]

        ):

            raise HTTPException(
                403,
                "Forbidden",
            )

        # Supervisor

        if (

            user["role"] == "SUPERVISOR"

            and

            site_id not in user.get(
                "site_ids",
                [],
            )

        ):

            raise HTTPException(
                403,
                "Not assigned",
            )

        # Client

        if (

            user["role"] == "CLIENT"

            and

            site.get(
                "client_email"
            ) != user["email"]

        ):

            raise HTTPException(
                403,
                "Forbidden",
            )

        return site

    # ============================================================
    # UPDATE SITE
    # ============================================================

    async def update_site(

        self,

        site_id: str,

        body,

        user,

    ):

        site = await site_repository.get(site_id)

        if not site:

            raise HTTPException(
                404,
                "Site not found",
            )

        if site["company_id"] != user["company_id"]:

            raise HTTPException(
                403,
                "Forbidden",
            )

        await site_repository.update(

            site_id,

            user["company_id"],

            body.model_dump(),

        )

        return await site_repository.get(site_id)

    # ============================================================
    # DELETE SITE
    # ============================================================

    async def delete_site(
        self,
        site_id: str,
        user: dict,
    ):

        site = await site_repository.get(site_id)

        if not site:
            raise HTTPException(
                404,
                "Site not found",
            )

        if site["company_id"] != user["company_id"]:
            raise HTTPException(
                403,
                "Forbidden",
            )

        await site_repository.delete(
            site_id,
            user["company_id"],
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

        site = await site_repository.get(site_id)

        if not site:

            raise HTTPException(
                404,
                "Site not found",
            )

        if site["company_id"] != user["company_id"]:

            raise HTTPException(
                403,
                "Forbidden",
            )

        supervisor = await site_repository.get_user(
            {
                "id": body.user_id,
                "company_id": user["company_id"],
                "role": "SUPERVISOR",
            }
        )

        if not supervisor:

            raise HTTPException(
                404,
                "Supervisor not found",
            )

        supervisor_ids = list(
            site.get(
                "supervisor_ids",
                [],
            )
        )

        if body.user_id not in supervisor_ids:

            supervisor_ids.append(
                body.user_id
            )

        names = []

        for supervisor_id in supervisor_ids:

            sup = await site_repository.get_user(
                {
                    "id": supervisor_id
                }
            )

            if sup:

                names.append(
                    sup["full_name"]
                )

        await site_repository.update_supervisors(

            site_id,

            supervisor_ids,

            names,

        )

        await site_repository.add_site_to_user(

            body.user_id,

            site_id,

        )

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
            site_id
        )

        if not site:

            raise HTTPException(
                404,
                "Site not found",
            )

        if site["company_id"] != user["company_id"]:

            raise HTTPException(
                403,
                "Forbidden",
            )

        client = await site_repository.get_user(
            {
                "id": body.user_id,
                "company_id": user["company_id"],
                "role": "CLIENT",
            }
        )

        if not client:

            raise HTTPException(
                404,
                "Client not found",
            )

        await site_repository.update_client(

            site_id,

            body.user_id,

            client["full_name"],

            client["email"],

        )

        await site_repository.add_site_to_user(

            body.user_id,

            site_id,

        )

        return {

            "success": True,

            "message": "Client assigned successfully",

        }

    # ============================================================
    # SUBSCRIPTION
    # ============================================================

    async def _validate_subscription(
        self,
        user,
    ):

        sub = await site_repository.active_subscription(
            user["company_id"]
        )

        plan = (
            sub or {}
        ).get(
            "plan",
            "FREE",
        )

        if plan == "FREE":

            count = await site_repository.company_site_count(
                user["company_id"]
            )

            if count >= 1:

                raise HTTPException(
                    402,
                    "Free plan allows only 1 site. Upgrade to Premium.",
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

        if not body.supervisor_ids:

            return []

        return await site_repository.get_supervisors(

            user["company_id"],

            body.supervisor_ids,

        )
        
        
    # ============================================================
    # LOAD CLIENT
    # ============================================================

    async def _load_client(
        self,
        body,
        user,
    ):

        if not body.client_id:

            return None

        return await site_repository.get_client(

            user["company_id"],

            body.client_id,

        )


    # ============================================================
    # BUILD DOCUMENT
    # ============================================================

    def _build_document(

        self,

        body,

        user,

        supervisors,

        client,

    ):

        data = body.model_dump()

        return {

            "id": new_id(),

            "company_id": user["company_id"],

            "created_by": user["id"],

            "created_at": now_iso(),

            **data,

            "supervisor_names":[

                s["full_name"]

                for s in supervisors

            ],

            "client_name":

                client.get("full_name")

                if client else None,

            "client_email":

                client.get("email")

                if client else None,

        }
        
    async def _assign_users(
        self,
        site_id,
        supervisors,
        client,
    ):

        for supervisor in supervisors:

            await site_repository.add_site_to_user(
                supervisor["id"],
                site_id,
            )
            
            await notification_service.notify_site_assigned(

                company_id=user["company_id"],

                user_id=supervisor["id"],

                site_name=site["name"],

            )

        if client:

            await site_repository.add_site_to_user(
                client["id"],
                site_id,
            )
            
            await notification_service.notify_site_assigned(
            
                            company_id=user["company_id"],
            
                            user_id=supervisor["id"],
            
                            site_name=site["name"],
            
                        )
            
    def _generate_default_tasks(
        self,
        body,
    ):

        tasks = [

            ("Site Layout",1),

            ("Excavation",2),

            ("Mitti Filling",2),

        ]

        if body.has_boring:

            tasks.append(
                ("Boring",2)
            )

        if body.has_septic_tank:

            tasks.append(
                ("Septic Tank",2)
            )

        if body.has_soak_pit:

            tasks.append(
                ("Soak Pit",2)
            )

        tasks.extend([
            ("PCC",3),
            ("Footing",4),
            ("Plinth Beam",4),
            ("GF Column",4),
            ("GF Brickwork",5),
            ("GF Slab",6),
        ])

        if body.floors >= 2:

            tasks.extend([
                ("FF Column",4),
                ("FF Brickwork",5),
                ("FF Slab",6),
            ])

        if body.floors >= 3:

            tasks.extend([
                ("SF Column",4),
                ("SF Brickwork",5),
                ("SF Slab",6),
            ])

        if body.floors >= 4:

            tasks.extend([
                ("TF Column",4),
                ("TF Brickwork",5),
                ("TF Slab",6),
            ])

        if body.has_mumty:

            tasks.extend([
                ("Mumty Brickwork",2),
                ("Mumty Slab",2),
            ])

        tasks.extend([
            ("Electrical",3),
            ("Plumbing",3),
            ("Flooring",3),
            ("Painting",3),
            ("Handover",1),
        ])

        return tasks

    site_service = SiteService()