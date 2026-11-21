from typing import Literal, Optional

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field

from core import db, get_current_user, new_id, now_iso, require_roles
from services.access_control import require_site_access

router = APIRouter(
    prefix="/api",
    tags=["Tasks"]
)


class TaskIn(BaseModel):
    site_id: str
    title: str = Field(min_length=2, max_length=180)
    due_at: Optional[str] = None
    weight: int = Field(default=1, ge=1, le=100)


class ScheduleIn(BaseModel):
    site_id: str
    title: str = Field(min_length=2, max_length=180)
    scheduled_at: str


class ApprovalDecisionIn(BaseModel):
    decision: Literal["APPROVED", "REJECTED"]
    note: Optional[str] = Field(default=None, max_length=500)


def _site_scope(user: dict) -> dict:
    if user["role"] == "CONTRACTOR":
        return {"company_id": user["company_id"]}
    return {
        "company_id": user["company_id"],
        "site_id": {"$in": user.get("site_ids", [])},
    }


async def _assert_site_access(site_id: str, user: dict, *, write: bool = False) -> dict:
    return await require_site_access(site_id, user, write=write)


async def _records(collection, query: dict) -> list[dict]:
    return await collection.find(query, {"_id": 0}).sort("created_at", -1).limit(500).to_list(500)


@router.get("/planning/overview")
async def planning_overview(user: dict = Depends(get_current_user)):
    """Role-scoped task, schedule and approval feed for the mobile workspace."""
    sites = await db.sites.find(_site_scope(user), {"_id": 0, "id": 1, "name": 1}).to_list(500)
    names = {site["id"]: site.get("name", "Site") for site in sites}
    site_scope = {"site_id": {"$in": list(names)}}
    company_scope = {"company_id": user["company_id"], **site_scope}
    tasks = await _records(db.site_tasks, company_scope)
    schedule = await _records(db.site_schedule, company_scope)
    approvals = await _records(db.site_approvals, company_scope)
    for group in (tasks, schedule, approvals):
        for record in group:
            record["site_name"] = names.get(record.get("site_id"), "Site")
    return {"tasks": tasks, "schedule": schedule, "approvals": approvals}


@router.post("/planning/tasks")
async def create_task(body: TaskIn, user: dict = Depends(require_roles("CONTRACTOR", "SUPERVISOR"))):
    await _assert_site_access(body.site_id, user, write=True)
    task = {
        "id": new_id(), "company_id": user["company_id"], "site_id": body.site_id,
        "title": body.title.strip(), "due_at": body.due_at, "weight": body.weight,
        "completed": False, "status": "OPEN", "created_by": user["id"], "created_at": now_iso(),
    }
    await db.site_tasks.insert_one(dict(task))
    return task


@router.post("/planning/schedule")
async def create_schedule_event(body: ScheduleIn, user: dict = Depends(require_roles("CONTRACTOR", "SUPERVISOR"))):
    await _assert_site_access(body.site_id, user, write=True)
    event = {"id": new_id(), "company_id": user["company_id"], "site_id": body.site_id, "title": body.title.strip(), "scheduled_at": body.scheduled_at, "status": "SCHEDULED", "created_by": user["id"], "created_at": now_iso()}
    await db.site_schedule.insert_one(dict(event))
    return event


@router.post("/planning/approvals/{approval_id}/decision")
async def decide_approval(approval_id: str, body: ApprovalDecisionIn, user: dict = Depends(require_roles("CONTRACTOR", "CLIENT"))):
    approval = await db.site_approvals.find_one({"id": approval_id, "company_id": user["company_id"]}, {"_id": 0})
    if not approval:
        raise HTTPException(404, "Approval not found")
    await _assert_site_access(approval["site_id"], user)
    patch = {"status": body.decision, "decision_note": body.note, "decided_by": user["id"], "decided_at": now_iso()}
    await db.site_approvals.update_one({"id": approval_id}, {"$set": patch})
    return {**approval, **patch}
