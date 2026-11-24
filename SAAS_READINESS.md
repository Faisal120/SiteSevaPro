# SiteSeva Pro web SaaS readiness

Mobile application work is out of the current launch scope. The production
surface is the React website/admin panel plus the FastAPI backend.

## Role model

| Role | Scope | Main capabilities |
| --- | --- | --- |
| Super Admin | Whole platform | Contractor applications, tenant activation/suspension, subscriptions and UPI approvals, design-credit approvals, revenue/audit views, WhatsApp delivery operations |
| Contractor | Own company | Sites, supervisor/client accounts, assignments, labour, material, expenses, payments, reports, estimates/BOQ, branding and subscription requests |
| Supervisor | Assigned sites | Site operations, attendance, material movement, expenses, labour wallet and daily reports |
| Client | Assigned sites, read-only | Project progress, client payments, shared reports/documents and notifications |

Backend authorization remains the source of truth. Frontend route guards hide
pages outside a role, while company/site checks prevent direct API access to
another tenant's data.

## Account lifecycle

1. A contractor submits the public registration form with an E.164-compatible
   WhatsApp number.
2. Super Admin approval atomically claims the application and provisions the
   company, contractor, free subscription and wallet.
3. A cryptographically generated temporary password is sent using the approved
   `siteseva_account_credentials` WhatsApp template. It is not returned to the
   admin browser.
4. The temporary account is restricted to `/auth/me` and password change until
   a strong new password is set.
5. Password change increments `password_version`, invalidating every previous
   JWT. Forgot password issues a hashed six-digit code with a 10-minute expiry,
   five-attempt lock and 15-minute request throttling.
6. Contractor-created Supervisor/Client accounts follow the same temporary
   credential and forced-change flow. Resending credentials generates a new
   password and invalidates old sessions.

## WhatsApp events

- Contractor application approval and initial credentials
- Supervisor/Client team credentials and credential resend
- Forgot-password OTP
- Subscription UPI payment approval
- Design-credit purchase approval
- Admin subscription activation and contractor reactivation

Every attempt has a delivery record. Meta webhook receipts update provider
states to `SENT`, `DELIVERED`, `READ`, or `FAILED`. External messaging failure
does not expose passwords or silently roll back an already-created account.

## Production gates

- Hostinger VPS (shared/static hosting cannot run this FastAPI/WebSocket stack)
- `sitesevapro.in`, `www`, and `api` DNS pointed to the VPS
- MongoDB Atlas VPS IP allow-list and production database user
- Meta WhatsApp production number, permanent token, approved templates and
  signed webhook configured as documented in `deploy/WHATSAPP_SETUP.md`
- Production Cloudinary and AI provider credentials
- New JWT/reset secrets and rotated database/API credentials before launch
- HTTPS, systemd, Nginx, database backup policy and uptime/error monitoring
- Four-role acceptance test using non-production phone numbers before real
  contractor approval

## Verification completed locally

- Python source compile
- Account security unit tests (phone normalization, password policy, temporary
  password generation and reset-code hashing)
- React optimized production build
- Real MongoDB-connected API startup and Super Admin authentication smoke test
- New auth/team/WhatsApp routes present in generated OpenAPI
