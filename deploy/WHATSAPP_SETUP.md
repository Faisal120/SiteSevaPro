# Meta WhatsApp Cloud API setup

SiteSeva uses only approved templates. API acceptance is recorded as `ACCEPTED`; it is not reported as delivered until Meta sends a signed delivery webhook.

## Required Meta templates

Create and approve the following names and language codes in WhatsApp Manager, then put the exact names/languages in `/etc/siteseva/backend.env`.

| Name | Category | parameters | use |
| --- | --- | --- | --- |
| `siteseva_account_approved` | Utility | customer name, company name, login ID | approved account notification, with a static `https://sitesevapro.in/login` website button configured in Meta |
| `siteseva_account_credentials` | Authentication / Copy Code | OTP | first-time password setup |
| `siteseva_password_reset` | Authentication / Copy Code | OTP | password recovery |
| `siteseva_approval_update` | Utility | customer name, application status, review details | registration application status only |

For each Authentication Copy Code template, configure a 10-minute expiry and its OTP button. The sender uses the body and URL-button parameter format below; it must match the approved button index and template language:

```json
{
  "messaging_product": "whatsapp",
  "to": "919876543210",
  "type": "template",
  "template": {
    "name": "siteseva_account_credentials",
    "language": {"code": "en"},
    "components": [
      {"type": "body", "parameters": [{"type": "text", "text": "123456"}]},
      {"type": "button", "sub_type": "url", "index": "0", "parameters": [{"type": "text", "text": "123456"}]}
    ]
  }
}
```

Meta’s template and Cloud API documentation should be checked against the approved templates before launch: [template reference](https://developers.facebook.com/docs/graph-api/reference/whats-app-business-account/message_templates/) and [Cloud API overview](https://developers.facebook.com/documentation/business-messaging/whatsapp/overview/).

## Webhook

Set the callback to `https://api.sitesevapro.in/api/whatsapp/webhook`, use `WHATSAPP_WEBHOOK_VERIFY_TOKEN`, and subscribe to `messages`. `WHATSAPP_APP_SECRET` is mandatory in production: missing or invalid `X-Hub-Signature-256` requests are rejected.

## Safe verification sequence

1. Use a consented test WhatsApp number and test/sandbox credentials.
2. Confirm account-approved messages contain Login ID only, never a password.
3. Request activation, copy the OTP, then complete password setup.
4. Confirm `ACCEPTED` progresses only through signed webhook receipts to `SENT`, `DELIVERED`, or `READ`.
5. Test a failed API request and a missing configuration; both must be `FAILED` or `NOT_CONFIGURED`, not delivery success.
