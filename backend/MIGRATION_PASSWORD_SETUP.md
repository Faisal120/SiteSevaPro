# Corrected password-setup migration

This is an additive, idempotent migration. It never creates a password, changes a password hash, sends a WhatsApp message, deletes a document, or prints sensitive records.

## Classification

- **Completed**: valid bcrypt hash plus an existing completed state, a legacy Super Admin, or a legacy normal-password account (`must_change_password` false/missing). These users retain normal login.
- **Eligible activation**: a valid-hash legacy `CONTRACTOR` with `must_change_password=true` and a linked application whose status is `APPROVED`. The migration sets `password_setup_required=true`, `password_setup_completed=false`, `account_status=PASSWORD_SETUP_REQUIRED`, and increments `password_version` so old JWTs are invalid.
- **Skipped**: blocked, suspended, disabled, rejected, inactive, unapproved, missing-hash, or malformed-hash accounts. No fields change.
- **Ambiguous**: conflicting new password-setup flags, a legacy `must_change_password` account without verified approved-contractor evidence, or a contractor linked to a non-approved application. No fields change; review these manually.

A missing `account_status` is neutral. It is not treated as blocked or unapproved. Valid bcrypt format is checked with bcrypt’s parser using a fixed probe; no password or hash value is logged.

## Safe procedure

1. Take/verify an Atlas backup and restore it into isolated staging.
2. Set only the intended staging `MONGO_URL` and `DB_NAME` in the shell. Do not use production credentials.
3. Run the default dry-run:

   ```bash
   cd /opt/siteseva
   /opt/siteseva/venv/bin/python backend/scripts/migrate_password_setup.py
   ```

4. Review the category/reason counts. Investigate every `ambiguous` record before proceeding.
5. Apply only after confirming the exact target name:

   ```bash
   /opt/siteseva/venv/bin/python backend/scripts/migrate_password_setup.py --apply --confirm-db YOUR_STAGING_DB_NAME
   ```

`--apply` refuses to run without `--confirm-db` exactly matching `DB_NAME`.

## Legacy outbound notifications

The dry-run/apply report counts only metadata for historic `ACCOUNT_CREDENTIALS`/credentials-template notification records. It never reads or prints content and never deletes records. Retain them for the approved audit-retention period, restrict admin/database access, and arrange secure deletion under the owner’s retention policy if historic plaintext credentials may have been stored outside the current notification schema.

## Verification

After an approved staging apply, confirm: Super Admin login still works; migrated approved contractors cannot use old JWTs or old temporary passwords; activation OTP completes password setup; blocked/rejected accounts remain ineligible; repeated runs report zero updates for already-classified records.
