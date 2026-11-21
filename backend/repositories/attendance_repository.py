from core import db
class AttendanceRepository:

    async def save(
        self,
        document: dict,
    ):

        await db.attendance.update_one(

            {
                "company_id": document["company_id"],
                "site_id": document["site_id"],
                "date": document["date"],
            },

            {
                "$set": document
            },

            upsert=True,

        )   

        return document


    async def get(
        self,
        site_id: str,
        date: str,
        company_id: str,
    ):

        return await db.attendance.find_one(

            {
                "company_id": company_id,
                "site_id": site_id,
                "date": date,
            },

            {
                "_id": 0
            }

        )


    async def history(
        self,
        site_id: str,
        company_id: str,
    ):

        return await (

            db.attendance

            .find(

                {
                    "company_id": company_id,
                    "site_id": site_id
                },

                {
                    "_id": 0
                }

            )

            .sort(

                "date",

                -1,

            )

            .limit(60)

            .to_list(60)

        )


    async def get_labours(
        self,
        labour_ids: list[str],
        company_id: str,
    ):

        cursor = db.labour.find(
            {
                "company_id": company_id,
                "id": {
                    "$in": labour_ids
                }
            },
            {
                "_id": 0
            }
        )

        return {
            labour["id"]: labour
            async for labour in cursor
        }


    async def clear_attendance_ledger(
        self,
        site_id: str,
        date: str,
        company_id: str,
    ):

        await db.labour_ledger.delete_many(
            {
                "company_id": company_id,
                "ref_type": "ATTENDANCE",
                "ref_date": date,
                "site_id": site_id,
            }
        )


    async def create_ledger_entry(
        self,
        document: dict,
    ):

        await db.labour_ledger.insert_one(
            document
        )
        
    async def get_site(
        self,
        site_id: str,
        company_id: str,
    ):

        return await db.sites.find_one(
            {
                "id": site_id,
                "company_id": company_id,
            },
            {
                "_id": 0
            }
        )

attendance_repository = AttendanceRepository()
