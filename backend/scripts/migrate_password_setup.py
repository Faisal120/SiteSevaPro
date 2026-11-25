#!/usr/bin/env python3
"""Idempotently add password-setup state to existing users.

Run with --dry-run first. This script never creates passwords, modifies hashes,
or deletes accounts. It intentionally requires --apply for writes.
"""
from __future__ import annotations

import argparse
import asyncio
import os

from dotenv import load_dotenv
from motor.motor_asyncio import AsyncIOMotorClient


async def run(apply: bool) -> None:
    load_dotenv()
    url = os.getenv("MONGO_URL") or os.getenv("MONGODB_URI")
    name = os.getenv("DB_NAME")
    if not url or not name:
        raise SystemExit("MONGO_URL (or MONGODB_URI) and DB_NAME are required")
    client = AsyncIOMotorClient(url)
    database = client[name]
    changed = 0
    async for user in database.users.find({}, {"id": 1, "password_hash": 1, "password_setup_required": 1, "password_setup_completed": 1, "account_status": 1}):
        has_password = bool(user.get("password_hash"))
        desired = (
            {"password_setup_required": False, "password_setup_completed": True}
            if has_password
            else {"password_setup_required": True, "password_setup_completed": False, "account_status": "PASSWORD_SETUP_REQUIRED", "must_change_password": True}
        )
        patch = {key: value for key, value in desired.items() if user.get(key) != value}
        if not patch:
            continue
        changed += 1
        if apply:
            await database.users.update_one({"_id": user["_id"]}, {"$set": patch})
    print(f"{'Applied' if apply else 'Dry run'}: {changed} user documents would be updated.")
    client.close()


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--apply", action="store_true", help="perform updates (default is dry run)")
    args = parser.parse_args()
    asyncio.run(run(args.apply))
