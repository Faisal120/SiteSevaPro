"""
Site APIs

SiteSeva Pro
Production Ready
"""

from fastapi import APIRouter, Depends, status

from core import (
    get_current_user,
    require_roles,
)

from models.site import (
    SiteAssignmentIn,
    SiteDetail,
    SiteIn,
    SiteSummary,
)

from services.site_service import site_service

router = APIRouter(
    prefix="/api/sites",
    tags=["Sites"],
)


# ==========================================================
# LIST SITES
# ==========================================================

@router.get(
    "",
    response_model=list[SiteSummary],
    status_code=status.HTTP_200_OK,
)
async def list_sites(
    user=Depends(get_current_user),
):
    return await site_service.list_sites(user)


# ==========================================================
# GET SITE
# ==========================================================

@router.get(
    "/{site_id}",
    response_model=SiteDetail,
    status_code=status.HTTP_200_OK,
)
async def get_site(
    site_id: str,
    user=Depends(get_current_user),
):
    return await site_service.get_site(
        site_id,
        user,
    )


# ==========================================================
# CREATE SITE
# ==========================================================

@router.post(
    "",
    response_model=SiteDetail,
    status_code=status.HTTP_201_CREATED,
)
async def create_site(
    body: SiteIn,
    user=Depends(
        require_roles("CONTRACTOR")
    ),
):
    return await site_service.create_site(
        body,
        user,
    )


# ==========================================================
# UPDATE SITE
# ==========================================================

@router.put(
    "/{site_id}",
    response_model=SiteDetail,
    status_code=status.HTTP_200_OK,
)
async def update_site(
    site_id: str,
    body: SiteIn,
    user=Depends(
        require_roles("CONTRACTOR")
    ),
):
    return await site_service.update_site(
        site_id,
        body,
        user,
    )


# ==========================================================
# DELETE SITE
# ==========================================================

@router.delete(
    "/{site_id}",
    status_code=status.HTTP_200_OK,
)
async def delete_site(
    site_id: str,
    user=Depends(
        require_roles("CONTRACTOR")
    ),
):
    return await site_service.delete_site(
        site_id,
        user,
    )


# ==========================================================
# ASSIGN SUPERVISOR
# ==========================================================

@router.post(
    "/{site_id}/assign-supervisor",
    status_code=status.HTTP_200_OK,
)
async def assign_supervisor(
    site_id: str,
    body: SiteAssignmentIn,
    user=Depends(
        require_roles("CONTRACTOR")
    ),
):
    return await site_service.assign_supervisor(
        site_id,
        body,
        user,
    )


# ==========================================================
# ASSIGN CLIENT
# ==========================================================

@router.post(
    "/{site_id}/assign-client",
    status_code=status.HTTP_200_OK,
)
async def assign_client(
    site_id: str,
    body: SiteAssignmentIn,
    user=Depends(
        require_roles("CONTRACTOR")
    ),
):
    return await site_service.assign_client(
        site_id,
        body,
        user,
    )