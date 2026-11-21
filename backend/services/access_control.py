"""Shared company and site access checks for API services."""

from fastapi import HTTPException

from core import db


def user_has_site_access(site: dict, user: dict) -> bool:
    """Return whether a non-admin user is assigned to a site."""
    role = user.get("role")
    if role in {"SUPER_ADMIN", "CONTRACTOR"}:
        return True

    user_id = user.get("id")
    legacy_site_ids = set(user.get("site_ids") or [])

    if role == "SUPERVISOR":
        assigned = set(site.get("supervisor_ids") or [])
        if site.get("supervisor_id"):
            assigned.add(site["supervisor_id"])
        return user_id in assigned or site.get("id") in legacy_site_ids

    if role == "CLIENT":
        assigned = set(site.get("client_ids") or [])
        if site.get("client_id"):
            assigned.add(site["client_id"])
        email_match = (
            str(site.get("client_email") or "").lower()
            == str(user.get("email") or "").lower()
        )
        return user_id in assigned or email_match or site.get("id") in legacy_site_ids

    return False


async def require_site_access(
    site_id: str,
    user: dict,
    *,
    write: bool = False,
) -> dict:
    """Load a company-scoped site and enforce role assignment."""
    site = await db.sites.find_one(
        {"id": site_id, "company_id": user.get("company_id")},
        {"_id": 0},
    )
    if not site:
        raise HTTPException(status_code=404, detail="Site not found")
    if not user_has_site_access(site, user):
        raise HTTPException(status_code=403, detail="You are not assigned to this site")
    if write and user.get("role") == "CLIENT":
        raise HTTPException(status_code=403, detail="Client accounts are read-only")
    return site
