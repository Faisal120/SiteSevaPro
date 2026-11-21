# AI Assistant Backend Contract

Feature 17 needs these authenticated FastAPI routes:

- `GET /api/ai-assistant/conversation`
- `POST /api/ai-assistant/messages`

The conversation response should contain `messages`, each with stable `id`,
`role` (`USER` or `ASSISTANT`), `content`, and `created_at`. A message request
uses `{ "message": "..." }` and must enforce the authenticated user's company,
role, and site access before grounding the AI response in SiteSeva data.

The client deliberately has no local answer generator. A `404` renders the
service as unavailable instead of creating fictitious replies.
