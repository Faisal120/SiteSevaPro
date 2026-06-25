from bson import ObjectId
from database import db
from utils import new_id, now_iso


async def create_wallet(company_id: str, credits: int = 0):

    wallet = await db.wallets.find_one(
        {
            "company_id": company_id
        }
    )

    if wallet:
        return wallet

    wallet = {
        "id": new_id(),
        "company_id": company_id,
        "credits": credits,
        "created_at": now_iso(),
        "updated_at": now_iso()
    }

    await db.wallets.insert_one(wallet)

    return wallet


async def get_wallet(company_id: str):

    wallet = await db.wallets.find_one(
        {
            "company_id": company_id
        }
    )

    if not wallet:

        wallet = await create_wallet(
            company_id,
            0
        )

    wallet.pop("_id", None)

    return wallet


async def deduct_credit(
    company_id: str,
    credits: int,
    reason: str
):

    wallet = await get_wallet(company_id)

    if wallet["credits"] < credits:

        return False

    new_balance = wallet["credits"] - credits

    await db.wallets.update_one(
        {
            "company_id": company_id
        },
        {
            "$set": {
                "credits": new_balance,
                "updated_at": now_iso()
            }
        }
    )

    await db.wallet_transactions.insert_one(
        {
            "id": new_id(),
            "wallet_id": wallet["id"],
            "company_id": company_id,
            "type": "DEBIT",
            "credits": credits,
            "reason": reason,
            "balance_after": new_balance,
            "created_at": now_iso()
        }
    )

    return True


async def add_credit(
    company_id: str,
    credits: int,
    reason: str
):

    wallet = await get_wallet(company_id)

    new_balance = wallet["credits"] + credits

    await db.wallets.update_one(
        {
            "company_id": company_id
        },
        {
            "$set": {
                "credits": new_balance,
                "updated_at": now_iso()
            }
        }
    )

    await db.wallet_transactions.insert_one(
        {
            "id": new_id(),
            "wallet_id": wallet["id"],
            "company_id": company_id,
            "type": "CREDIT",
            "credits": credits,
            "reason": reason,
            "balance_after": new_balance,
            "created_at": now_iso()
        }
    )

    return True


async def wallet_history(company_id: str):

    history = await db.wallet_transactions.find(
        {
            "company_id": company_id
        },
        {
            "_id": 0
        }
    ).sort(
        "created_at",
        -1
    ).to_list(500)

    return history