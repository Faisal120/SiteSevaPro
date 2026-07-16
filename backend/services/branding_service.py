from repositories.branding_repository import (
    branding_repository,
)


class BrandingService:

    async def get(
        self,
        company_id,
    ):

        return await branding_repository.get(
            company_id
        )

    async def update(
        self,
        company_id,
        body,
    ):

        return await branding_repository.save(
            company_id,
            body.model_dump(),
        )


branding_service = BrandingService()