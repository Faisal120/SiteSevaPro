# Meta WhatsApp Cloud API setup

SiteSeva sends only approved template messages through Meta's Cloud API. The
backend never logs the access token or returns temporary passwords to the admin
browser. Every attempt is stored in `outbound_notifications` and delivery/read
receipts are updated through the signed webhook.

## Meta assets required

1. A verified Meta Business Portfolio and WhatsApp Business Account.
2. A Meta developer app with the WhatsApp product enabled.
3. A production phone number and its **Phone number ID**.
4. A system user with `whatsapp_business_messaging` access and a permanent
   token. Do not use the temporary dashboard token in production.
5. The Meta app secret and a new random webhook verification token.

Meta sends templates through
`https://graph.facebook.com/{version}/{phone-number-id}/messages`. Template
names and parameter order must match the environment file exactly.

## Templates to create and approve

Create these in WhatsApp Manager using language `en`.

### `siteseva_account_credentials` — Utility

Body:

```text
Hello {{1}}, your SiteSeva Pro {{2}} account is ready.
Login email: {{3}}
Temporary password: {{4}}
Sign in: {{5}}
You must change this password on first login. Do not share it with anyone.
```

Parameter order: full name, role, email, temporary password, login URL.

### `siteseva_password_reset` — Authentication

Create an Authentication template with a 10-minute code expiry and the
**No button** OTP option. It must accept one body parameter: the six-digit
code. If Meta requires an OTP button for the selected account, the backend
payload must be extended to match that approved button before launch.

### `siteseva_approval_update` — Utility

Body:

```text
Hello {{1}}, your SiteSeva Pro update is ready.
{{2}}
{{3}}
```

Parameter order: recipient name, approval title, approval detail.

## Webhook

After DNS and HTTPS are active, configure this callback in the Meta app:

```text
https://api.sitesevapro.in/api/whatsapp/webhook
```

Use the exact value of `WHATSAPP_WEBHOOK_VERIFY_TOKEN` during verification,
subscribe to the `messages` field, and keep `WHATSAPP_APP_SECRET` configured so
the backend validates `X-Hub-Signature-256` on every callback.

## Environment

Copy all `WHATSAPP_*` entries from `siteseva.env.example` into
`/etc/siteseva/backend.env`. Restart the API, then check Super Admin → WhatsApp.
Its configuration card must be green before approving a real application.

## Safe launch test

1. Register a test contractor with a WhatsApp number opted in to receive the
   business's messages.
2. Approve it from Super Admin → Applications.
3. Confirm the delivery advances from `ACCEPTED` to `DELIVERED` or `READ`.
4. Sign in with the temporary password and confirm all APIs except password
   change are blocked until a new password is set.
5. Test Forgot password and confirm the code expires after 10 minutes.
