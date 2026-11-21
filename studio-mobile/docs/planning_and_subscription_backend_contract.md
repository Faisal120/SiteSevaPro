# Planning and Subscription Renewal Contract

## Feature 18: Tasks, schedule and approvals

Implement `GET /api/planning/overview` for the first mobile read surface:

```json
{
  "tasks": [{"id":"...","title":"...","status":"OPEN","site_name":"...","due_at":"..."}],
  "schedule": [{"id":"...","title":"...","status":"SCHEDULED","site_name":"...","scheduled_at":"..."}],
  "approvals": [{"id":"...","title":"...","status":"PENDING","site_name":"..."}]
}
```

Follow with role-protected create/update task, schedule, and approval-decision
routes before enabling mutations in the mobile app. The client currently shows
only records returned by this endpoint.

## Subscription renewal

Implement `POST /api/subscription/renewal/request` for contractors. Return a
server-generated request id and status such as `PENDING_VERIFICATION`; validate
the current subscription, organization, payment channel, and duplicate pending
requests server-side. `GET /api/subscription/current` remains the source of
truth for the resulting renewal date and active plan.
