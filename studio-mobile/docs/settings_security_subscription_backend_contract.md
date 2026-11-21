# Settings, Security and Subscription Contract

The mobile client reads `GET /api/auth/me` today. Profile, company,
preferences, subscription and password routes are now provided by the
SiteSevaPro-main Mobile Launch router.

## Workspace preferences

- `GET /api/company/preferences`
- `PATCH /api/company/preferences`

Return and accept `language`, `currency`, `measurement_system`, and
`timezone`. The authenticated contractor owns updates; supervisor and client
may read the resolved company values.

## Account security

- `PATCH /api/auth/password` with `current_password` and `new_password`
- `GET /api/auth/sessions`
- `DELETE /api/auth/sessions/{session_id}`
- `POST /api/auth/2fa/enroll`
- `POST /api/auth/2fa/verify`
- `DELETE /api/auth/2fa`

Each session must expose a stable id, device label, last active timestamp, IP
metadata when available, and whether it is the current session. Biometric
unlock is device-local but must respect a backend session-revocation policy.

## Subscription

`GET /api/subscription/current` returns:

```json
{
  "plan": "Pro",
  "status": "ACTIVE",
  "renews_at": "2026-10-01T00:00:00Z",
  "ai_credits_remaining": 120
}
```

Contractors may submit `POST /api/subscription/renewal/request`; the server
creates one pending request and a notification rather than activating a plan
before payment verification. Device sessions and 2FA still require dedicated
identity-provider/session infrastructure and are intentionally not faked.
