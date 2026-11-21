# Realtime Notifications Backend Contract

The current FastAPI backend exposes role-scoped REST notifications at `/api/notifications`, but it does not expose a WebSocket transport. Feature 14 adds an optional WebSocket client and keeps the existing REST polling path as the production fallback until this route is deployed.

## WebSocket route

```text
WS /api/notifications/stream
```

Authenticate the connection with the existing JWT bearer token in the WebSocket handshake. The server must scope the stream to the authenticated company, user, assigned sites and client sharing rules exactly as the REST endpoints do.

## Event envelope

The server may send a direct notification object or this envelope:

```json
{
  "event": "notification.created",
  "data": {
    "id": "notification-123",
    "company_id": "company-1",
    "user_id": null,
    "site_id": "site-1",
    "title": "Low Stock Alert",
    "message": "OPC cement stock needs replenishment.",
    "type": "MATERIAL",
    "priority": "HIGH",
    "read": false,
    "created_at": "2026-08-08T09:00:00Z"
  }
}
```

Supported client events are `notification.created`, `notification.updated`, and `notification.deleted`. For a deleted event, send the notification id and the Flutter client will rely on the next REST refresh to reconcile the feed.

## Delivery rules

- Send company-wide alerts with `user_id: null`; send personal alerts with the target user id.
- Preserve the canonical notification fields used by the REST API.
- Do not send records outside the authenticated user's role scope.
- Close or reject the socket when the JWT expires.
- REST endpoints remain authoritative for refresh, mark-read, mark-all-read and delete operations.

The Flutter client reconnects with exponential backoff and displays `Polling fallback active` when the WebSocket is unavailable. This avoids a broken notification center while the backend transport is being rolled out.
