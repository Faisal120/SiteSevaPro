# Password setup migration

The migration is additive and idempotent. It never generates passwords, deletes records, or changes a valid password hash.

1. Back up the target MongoDB database and use an isolated staging copy first.
2. On the intended host, export the target database environment only for that shell.
3. Run `python backend/scripts/migrate_password_setup.py` and review the dry-run count.
4. Run `python backend/scripts/migrate_password_setup.py --apply` only during an approved maintenance window.
5. Restart the API and verify the `auth_challenges` indexes were created.

Users with a valid `password_hash` are marked as already set up and retain their passwords. Accounts with no password hash become `PASSWORD_SETUP_REQUIRED`; they must use the activation OTP route. No production database operation has been performed by this repository change.
