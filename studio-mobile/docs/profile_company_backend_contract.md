# Profile & Company Backend Contract

Feature 14 intentionally uses only the currently deployed mobile contracts for
live data. The Flutter app does not infer account values or show fabricated
subscription metrics.

## Existing endpoints used by the app

All routes are under `/api` and require `Authorization: Bearer <jwt>`.

### `GET /auth/me`

Returns the authenticated workspace member. The mobile app reads:

```json
{
  "id": "user-id",
  "email": "member@example.com",
  "full_name": "Member name",
  "role": "CONTRACTOR",
  "username": "member",
  "company_id": "company-id",
  "company_name": "Company name",
  "plan": "PRO",
  "site_ids": [],
  "blocked": false,
  "created_at": "2026-08-08T09:00:00Z"
}
```

### `GET /branding`

Returns the workspace branding document. The app supports `company_name`,
`logo` or `logo_url`, `primary_color`, `secondary_color`, `accent_color`,
`font`, `email`, `phone`, `address`, `website` and `gst_number`.

### `PUT /branding`

Contractor-only mutation used for branding changes. The request body is:

```json
{
  "company_name": "Company name",
  "email": "office@example.com",
  "phone": "+91 9876543210",
  "address": "Registered address",
  "website": "https://example.com",
  "gst_number": "GSTIN",
  "primary_color": "#2563EB",
  "secondary_color": "#0A0E17",
  "accent_color": "#4F8CFF",
  "font": "Sora"
}
```

### `POST /branding/logo`

Contractor-only multipart upload. The multipart field must be named `file`.
The response should be the refreshed branding document, or an object containing
it under `branding`.

## Required backend additions

These routes are contract-ready in `ApiService`, but the Profile UI does not
call them until FastAPI exposes them. The current UI shows a read-only or
unavailable state instead of pretending these mutations succeeded.

### `PATCH /auth/profile`

Update the authenticated member's editable profile fields. Suggested allowed
fields: `full_name`, `username`, `phone`, `avatar_url`. The endpoint must return
the same shape as `GET /auth/me` and enforce the authenticated user's role.

### `GET /company/profile`

Return the full company record, including `legal_name`, `gst_number`, `address`,
`city`, `state`, `pincode`, `website`, `logo_url` and `created_at`. Access must
be scoped to the authenticated user's company and assigned workspace.

### `PATCH /company/profile`

Contractor-only company profile mutation. Supervisor and client requests must
return `403`. The response should be the complete company record.

### `GET /subscription/current`

Return the authenticated company's current subscription, entitlements and AI
credit balance. Suggested fields: `plan`, `status`, `started_at`, `renews_at`,
`ai_credits_remaining`, `sites_limit` and `members_limit`. Until this route is
live, the app displays only the `plan` value returned by `/auth/me`.
