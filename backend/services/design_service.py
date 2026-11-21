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

from design_core.design_constants import (
    COST_2D,
    COST_3D,
    COST_TECHNICAL_DRAWING,
)

from design_core.design_status import (
    DESIGN_COMPLETED,
    DESIGN_FAILED,
    DESIGN_PROCESSING,
)

from services.design_engine.project import Project
from services.technical_drawing_service import technical_drawing_service
from services.cad_pdf_service import cad_pdf_service
from services.three_d_renderer import three_d_renderer
from copy import copy

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

            floor_layouts = []
            requirements = {
                item.floor_number: item
                for item in getattr(body, "floor_requirements", [])
            }
            for floor_number in range(1, max(1, int(body.floors)) + 1):
                floor_body = copy(body)
                floor_body.floors = 1
                floor_body.variation = int(getattr(body, "variation", 0)) + floor_number - 1
                requirement = requirements.get(floor_number)
                if requirement:
                    for field, value in requirement.model_dump(exclude={"floor_number"}).items():
                        setattr(floor_body, field, value)

                # Parking and the vehicular entrance are a ground-floor site
                # feature. Upper floors are always generated without a bay.
                if floor_number > 1:
                    floor_body.parking = False
                    floor_body.garden = False
                generated = design_engine.generate(floor_body)
                generated.project = Project(company=user.get("company_name", ""), project_name=body.project_name, client_name="", architect=user.get("full_name", ""), location=body.site_id, revision=f"F{floor_number}")
                floor_layouts.append({"floor_number": floor_number, "label": "Ground Floor" if floor_number == 1 else f"Floor {floor_number - 1}", "layout": generated.response})
            layout = type("FloorLayout", (), {"response": floor_layouts[0]["layout"], "exports": {}})()

            # The design-engine renderer is the authoritative drawing.  The
            # legacy renderer used a second, incompatible drawing model and
            # could overwrite clean wall/opening geometry.
            svg = layout.response["svg"]

            # -------------------------------
            # Documentation
            # -------------------------------

            outputs = {
                "layout": layout.response,
                "svg": svg,
                "documents": layout.exports,
                "floor_plans": floor_layouts,
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

            await design_wallet_service.refund(
                user["company_id"],
                credits,
                f"Refund for failed {body.design_type} design · {design['id']}",
            )

            raise

    async def generate_3d(self, user, design_id, floor_number: int):
        design = await design_repository.get_by_id(design_id, user["company_id"])
        if not design:
            raise ValueError("Approved 2D plan not found.")
        plan = await subscription_repository.get_plan(user["company_id"])
        if plan == "FREE":
            raise ValueError("Upgrade to Pro or Enterprise to generate 3D plans.")
        floor_plans = (design.get("outputs") or {}).get("floor_plans") or []
        selected = next((item for item in floor_plans if item["floor_number"] == floor_number), None)
        if not selected:
            raise ValueError("Select a generated 2D floor before creating its 3D plan.")
        await design_wallet_service.consume(user["company_id"], COST_3D, f"3D plan · {selected['label']}")
        svg = three_d_renderer.render(selected["layout"], floor_number)
        outputs = design.get("outputs") or {}
        three_d = outputs.get("three_d") or {}
        three_d[str(floor_number)] = {"floor_number": floor_number, "label": selected["label"], "svg": svg}
        outputs["three_d"] = three_d
        await design_repository.update(design_id, {"outputs": outputs})
        design["outputs"] = outputs
        return design

    async def list(
        self,
        user,
    ):

        return await design_repository.list(
            user["company_id"]
        )

    async def create_technical_drawing(
        self,
        user,
        design_id,
        drawing_type,
    ):
        drawing_type = drawing_type.upper()
        if drawing_type not in technical_drawing_service.DRAWING_TYPES:
            raise ValueError("Choose electrical, plumbing, column, structural, foundation, or door/window schedule.")

        design = await design_repository.get_by_id(
            design_id,
            user["company_id"],
        )
        if not design:
            raise ValueError("Floor plan not found.")

        await design_wallet_service.consume(
            user["company_id"],
            COST_TECHNICAL_DRAWING,
            f"{drawing_type.title()} technical drawing",
        )

        outputs = design.get("outputs") or {}
        technical_drawings = outputs.get("technical_drawings") or {}
        technical_drawings[drawing_type] = technical_drawing_service.render(
            outputs.get("layout") or {},
            drawing_type,
        )
        outputs["technical_drawings"] = technical_drawings

        updated = await design_repository.update(
            design_id,
            {"outputs": outputs},
        )
        return updated

    async def get_pdf_drawing(
        self,
        user,
        design_id,
        drawing_type,
        floor_number: int = 1,
    ):
        drawing_type = drawing_type.upper()
        if drawing_type not in cad_pdf_service.DRAWING_TYPES:
            raise ValueError("Unsupported PDF drawing type.")

        design = await design_repository.get_by_id(design_id, user["company_id"])
        if not design:
            raise ValueError("Floor plan not found.")

        outputs = design.get("outputs") or {}
        layout = outputs.get("layout")
        if drawing_type == "FLOOR":
            selected_floor = next(
                (item for item in outputs.get("floor_plans", []) if item.get("floor_number") == floor_number),
                None,
            )
            if selected_floor:
                layout = selected_floor.get("layout")
        if not layout:
            raise ValueError("The floor plan has no drawing data.")

        if drawing_type != "FLOOR":
            technical_drawings = (design.get("outputs") or {}).get("technical_drawings") or {}
            if drawing_type not in technical_drawings:
                raise ValueError("Generate this technical drawing before downloading its PDF.")

        return cad_pdf_service.build(
            layout,
            drawing_type,
            design.get("project_name", "Untitled Project"),
            design.get("site_id", ""),
        )

    async def get(
        self,
        user,
        design_id,
    ):

        return await design_repository.get_by_id(
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
