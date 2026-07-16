from repositories.design_repository import design_repository

from repositories.subscription_repository import (
    subscription_repository,
)

from services.design_wallet_service import (
    design_wallet_service,
)

from services.design_engine.engine import (
    design_engine,
)

from services.design_engine.documentation.documentation_engine import (
    documentation_engine,
)

from services.svg_renderer import (
    svg_renderer,
)

from design_core.design_constants import (
    COST_2D,
    COST_3D,
)

from design_core.design_status import (
    DESIGN_COMPLETED,
    DESIGN_FAILED,
    DESIGN_PROCESSING,
)


class DesignService:

    async def create(
    self,
    user,
    body,
):
        credits = COST_2D

        if body.design_type == "3D":
            credits = COST_3D

        plan = await subscription_repository.get_plan(
            user["company_id"]
        )

        if body.design_type == "3D" and plan == "FREE":
            raise Exception(
                "Upgrade to PRO to generate 3D designs."
            )

        await design_wallet_service.consume(
            user["company_id"],
            credits,
            f"{body.design_type} Design",
        )

        design = {
            "company_id": user["company_id"],
            "project_name": body.project_name,
            "site_id": body.site_id,
            "design_type": body.design_type,
            "credits_used": credits,
            "status": DESIGN_PROCESSING,
            "inputs": body.model_dump(),
            "outputs": {},
        }

        design = await design_repository.create(
            design
        )

        try:

            # -------------------------------
            # Generate Design
            # -------------------------------

            layout = design_engine.generate(
                body
            )

            # -------------------------------
            # SVG
            # -------------------------------

            svg = svg_renderer.render(
                layout
            )

            # -------------------------------
            # Documentation
            # -------------------------------

            docs = documentation_engine.generate(
                layout
            )

            outputs = {
                "layout": layout,
                "svg": svg,
                "documents": docs,
            }

            await design_repository.update(
                design["id"],
                {
                    "status": DESIGN_COMPLETED,
                    "outputs": outputs,
                },
            )

            design["status"] = DESIGN_COMPLETED
            design["outputs"] = outputs

            return design

        except Exception as e:

            await design_repository.update(
                design["id"],
                {
                    "status": DESIGN_FAILED,
                    "error": str(e),
                },
            )

            raise

    async def list(
        self,
        user,
    ):

        return await design_repository.list(
            user["company_id"]
        )

    async def get(
        self,
        user,
        design_id,
    ):

        return await design_repository.get(
            design_id,
            user["company_id"],
        )
        
        
    async def delete(
    self,
    user,
    design_id,
):

        await design_repository.delete(

            design_id,

            user["company_id"],

        )

        return {

            "success": True

        }


design_service = DesignService()