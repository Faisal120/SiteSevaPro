# Site Team Assignment Contract

The Site creation and assignment workflow consumes existing authenticated
FastAPI endpoints:

- `GET /api/team`
- `POST /api/sites/{site_id}/assign-supervisor` with `{ "user_id": "..." }`
- `POST /api/sites/{site_id}/assign-client` with `{ "user_id": "..." }`
- `POST /api/sites` and `PUT /api/sites/{site_id}` with `supervisor_ids` and
  `client_id` in the Site payload.

`GET /api/team` needs to return a stable `id`, `role`, and at least one of
`full_name`, `name`, or `username`; `email` is optional. The mobile app only
offers `SUPERVISOR` members for supervisor assignment and `CLIENT` members for
client assignment. It never creates personnel records locally.

After an assignment mutation, the app refreshes the Site portfolio, site
detail, and dashboard data so role-scoped users receive the new project access
from the backend on their next session refresh.
