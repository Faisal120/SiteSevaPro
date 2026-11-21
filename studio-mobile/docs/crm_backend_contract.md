# CRM Backend Contract

SiteSevaPro-main now exposes the authenticated CRM workspace through the Mobile
Launch router. The Flutter Feature 12 client consumes these live endpoints:

- `GET /api/crm/overview`
- `POST /api/crm/leads`
- `POST /api/crm/contacts`
- `POST /api/crm/activities`
- `PATCH /api/crm/activities/{activity_id}`
- `POST /api/crm/quotations`

All records are scoped to the authenticated company. Contractor owns leads,
contacts, and quotations; Contractor and Supervisor can create and complete
activities.

## Routes

All routes require the existing JWT bearer authentication and company/role scoping used by the rest of the API.

| Method | Route | Roles | Purpose |
| --- | --- | --- | --- |
| `GET` | `/api/crm/overview?q=&workspace=` | Contractor, Supervisor, Client | Return the CRM workspace snapshot, filtered to the authenticated company and assigned sites. |
| `POST` | `/api/crm/leads` | Contractor | Create a lead. |
| `POST` | `/api/crm/contacts` | Contractor | Create a client, vendor or other relationship contact. |
| `POST` | `/api/crm/activities` | Contractor, Supervisor | Create a meeting, call, follow-up or note. |
| `PATCH` | `/api/crm/activities/{activity_id}` | Contractor, Supervisor | Update activity status, including completing a follow-up. |
| `POST` | `/api/crm/quotations` | Contractor | Create a quotation linked to a contact. |

The Flutter `ApiService` uses the path after the configured API prefix, so the client calls `/crm/...` and the deployed FastAPI application should expose these under its existing `/api` prefix.

## Overview response

```json
{
  "metrics": {
    "leads": 0,
    "active_clients": 0,
    "vendors": 0,
    "open_follow_ups": 0,
    "pipeline_value": 0,
    "quotations": 0
  },
  "leads": [],
  "clients": [],
  "vendors": [],
  "activities": [],
  "quotations": []
}
```

`contacts` may be returned instead of `clients` and `vendors`; the Flutter parser separates contacts by `kind`. Activities may also be named `meetings` or `follow_ups`, and quotations may also be named `quotes`.

## Write payloads

Lead fields: `name`, `company`, `email`, `phone`, `source`, `estimated_value`.

Contact fields: `kind`, `name`, `company`, `email`, `phone`, `city`, `gstin`.

Activity fields: `kind`, `title`, `description`, `contact_id`, `scheduled_at`.

Quotation fields: `title`, `contact_id`, `amount`, `valid_until`.

## Role policy

- Contractor: full CRM read/write access for the company.
- Supervisor: read CRM records and create or complete field follow-ups.
- Client: read-only access to records shared with the assigned project scope.

The API must enforce this policy server-side. The Flutter role checks are only a UX guard and are not a security boundary.
