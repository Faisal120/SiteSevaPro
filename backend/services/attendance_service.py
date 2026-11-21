from repositories.attendance_repository import attendance_repository

from core import new_id, now_iso

from fastapi import HTTPException

from v2 import (
    ATTENDANCE_RATE,
    recompute_wallet,
    log_audit,
)

from services.notification_service import (
    notification_service,
)
from services.access_control import require_site_access


class AttendanceService:

    def _normalize_entries(self, body):

        entries = []

        for e in body.entries:

            status = e.get("status")

            if not status:
                status = "PRESENT" if e.get("present") else "ABSENT"

            entries.append({

                "labour_id": e["labour_id"],

                "status": status,

                "overtime_hours": float(
                    e.get("overtime_hours") or 0
                ),

                "advance": float(
                    e.get("advance") or 0
                ),

            })

        return entries

    async def _save_attendance(
        self,
        body,
        entries,
        user,
    ):

        document = {

            "id": new_id(),

            "company_id": user["company_id"],

            "site_id": body.site_id,

            "date": body.date,

            "entries": entries,

            "marked_by": user["id"],

            "created_at": now_iso(),

        }

        await attendance_repository.save(

            document,

        )
        
        await notification_service.notify_attendance(

            company_id=user["company_id"],

            site_id=body.site_id,

            marked_by=user["id"],

            total_labours=len(entries),

        )

        return document
    
    
    async def mark_attendance(
    self,
    body,
    user,
):

        await require_site_access(body.site_id, user, write=True)

        # -----------------------------------
        # Normalize Entries
        # -----------------------------------

        norm_entries = []

        for e in body.entries:

            status = e.status

            norm_entries.append({

                "labour_id": e.labour_id,

                "status": status,

                "overtime_hours": float(
                    e.overtime_hours
                ),

                "advance": float(
                    e.advance
                ),

            })

        # -----------------------------------
        # Attendance Document
        # -----------------------------------

        doc = {

            "id": new_id(),

            "company_id": user["company_id"],

            "site_id": body.site_id,

            "date": body.date,

            "entries": norm_entries,

            "marked_by": user["id"],

            "created_at": now_iso(),

        }

        attendance = await attendance_repository.save(
            doc
        )
        
        await notification_service.notify_attendance(

            company_id=user["company_id"],

            site_id=body.site_id,

            marked_by=user["id"],

            total_labours=len(norm_entries),

        )

        await self._create_ledger(
            attendance,
            norm_entries,
            user,
        )

        await log_audit(
            user,
            "UPDATE",
            "attendance",
            attendance["id"],
            {
                "site_id": attendance["site_id"],
                "date": attendance["date"],
                "count": len(norm_entries),
            },
        )

        return attendance

    async def get_attendance(
    self,
    site_id,
    date,
    user,
):

        site = await attendance_repository.get_site(
            site_id,
            user["company_id"],
        )

        if not site:
            raise HTTPException(
                404,
                "Site not found",
            )

        await require_site_access(site_id, user)

        if date:

            attendance = await attendance_repository.get(
                site_id,
                date,
                user["company_id"],
            )

            if attendance:

                return attendance

            return {
                "site_id": site_id,
                "date": date,
                "entries": [],
            }

        return await attendance_repository.history(
            site_id,
            user["company_id"],
        )


    async def _create_ledger(
        self,
        attendance,
        entries,
        user,
    ):

        await attendance_repository.clear_attendance_ledger(

            attendance["site_id"],

            attendance["date"],

            user["company_id"],

        )

        labour_ids = [

            entry["labour_id"]

            for entry in entries

        ]

        labours = await attendance_repository.get_labours(

            labour_ids,

            user["company_id"],

        )

        touched = set()

        for entry in entries:

            labour = labours.get(

                entry["labour_id"]

            )

            if labour is None:

                continue

            wage = labour.get(

                "daily_wage",

                0,

            )

            factor = ATTENDANCE_RATE.get(

                entry["status"],

                0,

            )

            wage_amount = round(

                wage * factor,

                2,

            )

            overtime_amount = 0

            if entry["overtime_hours"]:

                overtime_amount = round(

                    (wage / 8) *

                    entry["overtime_hours"],

                    2,

                )

            total = wage_amount + overtime_amount

            if total > 0:

                await attendance_repository.create_ledger_entry(

                    {

                        "id": new_id(),

                        "company_id": user["company_id"],

                        "labour_id": entry["labour_id"],

                        "site_id": attendance["site_id"],

                        "type": "EARNING",

                        "amount": total,

                        "note": f"{entry['status']} wage",

                        "date": attendance["date"],

                        "ref_type": "ATTENDANCE",

                        "ref_id": attendance["id"],

                        "ref_date": attendance["date"],

                        "created_at": now_iso(),

                    }

                )

                touched.add(

                    entry["labour_id"]

                )

            if entry["advance"] > 0:

                await attendance_repository.create_ledger_entry(

                    {

                        "id": new_id(),

                        "company_id": user["company_id"],

                        "labour_id": entry["labour_id"],

                        "site_id": attendance["site_id"],

                        "type": "ADVANCE",

                        "amount": entry["advance"],

                        "note": "Daily advance",

                        "date": attendance["date"],

                        "ref_type": "ATTENDANCE",

                        "ref_id": attendance["id"],

                        "ref_date": attendance["date"],

                        "created_at": now_iso(),

                    }

                )

                touched.add(

                    entry["labour_id"]

                )

        for labour_id in touched:

            await recompute_wallet(

                labour_id

            )
        
        
attendance_service = AttendanceService()
