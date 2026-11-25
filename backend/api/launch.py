"""Production mobile API slice for profile, CRM, documents, and preferences.

The routes in this module are intentionally company-scoped and only store
metadata for Cloudinary assets. File bytes remain in Cloudinary, so document
downloads never proxy private data through an unbounded FastAPI response.
"""
from __future__ import annotations

from typing import Literal, Optional

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field
from starlette.responses import RedirectResponse

from core import db, get_current_user, hash_password, new_id, now_iso, require_roles, verify_password
from services.access_control import require_site_access
from services.account_security import validate_password_strength

router = APIRouter(prefix="/api", tags=["Mobile Launch"])


class ProfileIn(BaseModel):
    full_name: str = Field(min_length=2, max_length=120)


class ProfileOut(BaseModel):
    id: str
    email: str
    full_name: str
    username: Optional[str] = None
    role: str
    company_id: Optional[str] = None
    company_name: Optional[str] = None
    phone: Optional[str] = None
    whatsapp: Optional[str] = None
    must_change_password: bool = False


class PasswordIn(BaseModel):
    current_password: str = Field(min_length=8, max_length=256)
    new_password: str = Field(min_length=12, max_length=256)


class CompanyProfileIn(BaseModel):
    legal_name: Optional[str] = Field(default=None, max_length=160)
    email: Optional[str] = Field(default=None, max_length=160)
    phone: Optional[str] = Field(default=None, max_length=32)
    website: Optional[str] = Field(default=None, max_length=240)
    gst_number: Optional[str] = Field(default=None, max_length=32)
    address: Optional[str] = Field(default=None, max_length=400)
    city: Optional[str] = Field(default=None, max_length=80)
    state: Optional[str] = Field(default=None, max_length=80)
    pincode: Optional[str] = Field(default=None, max_length=16)


class PreferencesIn(BaseModel):
    language: str = Field(default="en", min_length=2, max_length=12)
    currency: str = Field(default="INR", min_length=3, max_length=6)
    measurement_system: Literal["METRIC", "IMPERIAL"] = "METRIC"
    timezone: str = Field(default="Asia/Kolkata", min_length=3, max_length=80)


class DocumentIn(BaseModel):
    site_id: Optional[str] = None
    name: str = Field(min_length=2, max_length=180)
    kind: str = Field(default="OTHER", max_length=40)
    description: Optional[str] = Field(default=None, max_length=800)
    shared_with_client: bool = False
    url: str = Field(min_length=8, max_length=2048)
    secure_url: Optional[str] = Field(default=None, max_length=2048)
    public_id: Optional[str] = Field(default=None, max_length=320)
    resource_type: Optional[str] = Field(default=None, max_length=40)
    mime_type: Optional[str] = Field(default=None, max_length=120)
    size_bytes: Optional[int] = Field(default=None, ge=0)
    original_filename: Optional[str] = Field(default=None, max_length=320)


class DocumentPatchIn(BaseModel):
    name: Optional[str] = Field(default=None, min_length=2, max_length=180)
    kind: Optional[str] = Field(default=None, max_length=40)
    description: Optional[str] = Field(default=None, max_length=800)
    shared_with_client: Optional[bool] = None


class CrmLeadIn(BaseModel):
    name: str = Field(min_length=2, max_length=160)
    company: Optional[str] = Field(default=None, max_length=160)
    email: Optional[str] = Field(default=None, max_length=160)
    phone: Optional[str] = Field(default=None, max_length=32)
    source: Optional[str] = Field(default=None, max_length=80)
    value: float = Field(default=0, ge=0)
    estimated_value: Optional[float] = Field(default=None, ge=0)


class CrmContactIn(BaseModel):
    name: str = Field(min_length=2, max_length=160)
    company: Optional[str] = Field(default=None, max_length=160)
    kind: Literal["CLIENT", "VENDOR", "ARCHITECT", "BUILDER"] = "CLIENT"
    email: Optional[str] = Field(default=None, max_length=160)
    phone: Optional[str] = Field(default=None, max_length=32)
    city: Optional[str] = Field(default=None, max_length=80)
    gstin: Optional[str] = Field(default=None, max_length=32)


class CrmActivityIn(BaseModel):
    kind: Literal["MEETING", "CALL", "FOLLOW_UP", "NOTE"] = "FOLLOW_UP"
    title: str = Field(min_length=2, max_length=180)
    description: Optional[str] = Field(default=None, max_length=1000)
    contact_name: Optional[str] = Field(default=None, max_length=160)
    contact_id: Optional[str] = Field(default=None, max_length=120)
    scheduled_at: Optional[str] = None


class CrmQuotationIn(BaseModel):
    title: str = Field(min_length=2, max_length=180)
    contact_name: Optional[str] = Field(default=None, max_length=160)
    contact_id: Optional[str] = Field(default=None, max_length=120)
    amount: float = Field(default=0, ge=0)
    valid_until: Optional[str] = None


def _company_query(user: dict) -> dict:
    return {"company_id": user["company_id"]}


def _record(doc: dict) -> dict:
    return {key: value for key, value in doc.items() if key != "_id"}


async def _verify_site(user: dict, site_id: Optional[str]) -> None:
    if not site_id:
        return
    await require_site_access(site_id, user)


@router.patch("/auth/profile", response_model=ProfileOut)
async def update_profile(body: ProfileIn, user: dict = Depends(get_current_user)):
    full_name = body.full_name.strip()
    await db.users.update_one({"id": user["id"]}, {"$set": {"full_name": full_name}})
    safe_fields = ProfileOut.model_fields.keys()
    updated = {key: user.get(key) for key in safe_fields}
    updated["full_name"] = full_name
    return updated


@router.patch("/auth/password")
async def change_password(body: PasswordIn, user: dict = Depends(get_current_user)):
    if not verify_password(body.current_password, user.get("password_hash", "")):
        raise HTTPException(400, "Current password is incorrect")
    if body.current_password == body.new_password:
        raise HTTPException(400, "Choose a new password")
    validate_password_strength(body.new_password)
    await db.users.update_one(
        {"id": user["id"]},
        {
            "$set": {
                "password_hash": hash_password(body.new_password),
                "password_changed_at": now_iso(),
                "must_change_password": False,
            },
            "$inc": {"password_version": 1},
        },
    )
    await db.password_reset_codes.update_many(
        {"user_id": user["id"], "status": "PENDING"},
        {"$set": {"status": "SUPERSEDED", "updated_at": now_iso()}},
    )
    await db.auth_challenges.update_many(
        {"user_id": user["id"], "status": {"$in": ["PENDING", "VERIFIED"]}},
        {"$set": {"status": "SUPERSEDED", "updated_at": now_iso()}},
    )
    return {"ok": True}


@router.get("/company/profile")
async def get_company_profile(user: dict = Depends(get_current_user)):
    company = await db.companies.find_one({"id": user["company_id"]}, {"_id": 0})
    if not company:
        raise HTTPException(404, "Company not found")
    return company


@router.patch("/company/profile")
async def update_company_profile(body: CompanyProfileIn, user: dict = Depends(require_roles("CONTRACTOR"))):
    patch = {key: value for key, value in body.model_dump().items() if value is not None}
    patch["updated_at"] = now_iso()
    await db.companies.update_one({"id": user["company_id"]}, {"$set": patch})
    return await get_company_profile(user)


@router.get("/company/preferences")
async def get_company_preferences(user: dict = Depends(get_current_user)):
    company = await db.companies.find_one({"id": user["company_id"]}, {"_id": 0, "preferences": 1}) or {}
    return company.get("preferences", {"language": "en", "currency": "INR", "measurement_system": "METRIC", "timezone": "Asia/Kolkata"})


@router.patch("/company/preferences")
async def update_company_preferences(body: PreferencesIn, user: dict = Depends(require_roles("CONTRACTOR"))):
    preferences = body.model_dump()
    await db.companies.update_one({"id": user["company_id"]}, {"$set": {"preferences": preferences, "updated_at": now_iso()}})
    return preferences


@router.get("/documents")
async def list_documents(site_id: Optional[str] = None, kind: Optional[str] = None, q: Optional[str] = None, user: dict = Depends(get_current_user)):
    query = _company_query(user)
    if site_id:
        await _verify_site(user, site_id)
        query["site_id"] = site_id
    elif user["role"] != "CONTRACTOR":
        query["site_id"] = {"$in": user.get("site_ids", [])}
    if user["role"] == "CLIENT":
        query["shared_with_client"] = True
    if kind:
        query["kind"] = kind.upper()
    if q and q.strip():
        query["name"] = {"$regex": q.strip(), "$options": "i"}
    return await db.documents.find(query, {"_id": 0}).sort("created_at", -1).limit(500).to_list(500)


@router.post("/documents")
async def create_document(body: DocumentIn, user: dict = Depends(require_roles("CONTRACTOR", "SUPERVISOR"))):
    await _verify_site(user, body.site_id)
    doc = {"id": new_id(), "company_id": user["company_id"], "created_by": user["id"], "created_at": now_iso(), **body.model_dump()}
    doc["kind"] = doc["kind"].upper()
    doc["asset_url"] = doc["secure_url"] or doc["url"]
    await db.documents.insert_one(dict(doc))
    return doc


@router.patch("/documents/{document_id}")
async def update_document(document_id: str, body: DocumentPatchIn, user: dict = Depends(require_roles("CONTRACTOR", "SUPERVISOR"))):
    existing = await db.documents.find_one({"id": document_id, **_company_query(user)}, {"_id": 0})
    if not existing:
        raise HTTPException(404, "Document not found")
    await _verify_site(user, existing.get("site_id"))
    patch = body.model_dump(exclude_unset=True)
    if "kind" in patch and patch["kind"] is not None:
        patch["kind"] = patch["kind"].upper()
    patch["updated_at"] = now_iso()
    await db.documents.update_one(
        {"id": document_id, **_company_query(user)},
        {"$set": patch},
    )
    return {**existing, **patch}


@router.delete("/documents/{document_id}")
async def delete_document(document_id: str, user: dict = Depends(require_roles("CONTRACTOR", "SUPERVISOR"))):
    existing = await db.documents.find_one({"id": document_id, **_company_query(user)}, {"_id": 0})
    if not existing:
        raise HTTPException(404, "Document not found")
    await _verify_site(user, existing.get("site_id"))
    await db.documents.delete_one({"id": document_id, **_company_query(user)})
    return {"ok": True}


@router.get("/documents/{document_id}/download")
async def document_download(document_id: str, user: dict = Depends(get_current_user)):
    existing = await db.documents.find_one({"id": document_id, **_company_query(user)}, {"_id": 0})
    if not existing:
        raise HTTPException(404, "Document not found")
    if user["role"] == "CLIENT" and not existing.get("shared_with_client"):
        raise HTTPException(403, "This document has not been shared with the client")
    await _verify_site(user, existing.get("site_id"))
    return RedirectResponse(existing.get("asset_url") or existing["url"], status_code=307)


async def _crm_list(name: str, user: dict) -> list[dict]:
    return await db[name].find(_company_query(user), {"_id": 0}).sort("created_at", -1).limit(500).to_list(500)


@router.get("/crm/overview")
async def crm_overview(user: dict = Depends(require_roles("CONTRACTOR", "SUPERVISOR"))):
    leads, contacts, activities, quotations = await _crm_list("crm_leads", user), await _crm_list("crm_contacts", user), await _crm_list("crm_activities", user), await _crm_list("crm_quotations", user)
    clients = [item for item in contacts if item.get("kind") == "CLIENT"]
    vendors = [item for item in contacts if item.get("kind") == "VENDOR"]
    return {"leads": leads, "clients": clients, "vendors": vendors, "activities": activities, "quotations": quotations}


async def _crm_insert(collection: str, payload: dict, user: dict) -> dict:
    doc = {"id": new_id(), "company_id": user["company_id"], "created_by": user["id"], "created_at": now_iso(), **payload}
    await db[collection].insert_one(dict(doc))
    return doc


@router.post("/crm/leads")
async def create_crm_lead(body: CrmLeadIn, user: dict = Depends(require_roles("CONTRACTOR"))):
    payload = body.model_dump()
    payload["value"] = body.estimated_value if body.estimated_value is not None else body.value
    payload.pop("estimated_value", None)
    return await _crm_insert("crm_leads", {**payload, "stage": "NEW"}, user)


@router.post("/crm/contacts")
async def create_crm_contact(body: CrmContactIn, user: dict = Depends(require_roles("CONTRACTOR"))):
    return await _crm_insert("crm_contacts", body.model_dump(), user)


@router.post("/crm/activities")
async def create_crm_activity(body: CrmActivityIn, user: dict = Depends(require_roles("CONTRACTOR", "SUPERVISOR"))):
    payload = body.model_dump()
    if body.contact_id and not body.contact_name:
        contact = await db.crm_contacts.find_one({"id": body.contact_id, **_company_query(user)}, {"_id": 0, "name": 1})
        payload["contact_name"] = (contact or {}).get("name")
    return await _crm_insert("crm_activities", {**payload, "status": "OPEN"}, user)


@router.patch("/crm/activities/{activity_id}")
async def update_crm_activity(activity_id: str, patch: dict, user: dict = Depends(require_roles("CONTRACTOR", "SUPERVISOR"))):
    existing = await db.crm_activities.find_one({"id": activity_id, **_company_query(user)}, {"_id": 0})
    if not existing:
        raise HTTPException(404, "CRM activity not found")
    allowed = {"status", "title", "description", "scheduled_at"}
    update = {key: value for key, value in patch.items() if key in allowed}
    update["updated_at"] = now_iso()
    await db.crm_activities.update_one(
        {"id": activity_id, **_company_query(user)},
        {"$set": update},
    )
    return {**existing, **update}


@router.post("/crm/quotations")
async def create_crm_quotation(body: CrmQuotationIn, user: dict = Depends(require_roles("CONTRACTOR"))):
    number = f"Q-{now_iso()[:10].replace('-', '')}-{new_id()[:6].upper()}"
    payload = body.model_dump()
    if body.contact_id and not body.contact_name:
        contact = await db.crm_contacts.find_one({"id": body.contact_id, **_company_query(user)}, {"_id": 0, "name": 1})
        payload["contact_name"] = (contact or {}).get("name")
    return await _crm_insert("crm_quotations", {**payload, "number": number, "status": "DRAFT"}, user)
