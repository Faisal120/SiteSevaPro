# Site Seva Pro — PRD

## Original Problem
SaaS for Indian construction site management (Site Seva Pro). Roles: Super Admin, Contractor, Supervisor, Client. Modules: Sites, Labour+Attendance, Materials, Payments, Daily Reports, Notifications, Subscriptions, AI Insights, Admin panel. Premium SaaS UI with dark charcoal + orange accents.

## Architecture
- Backend: FastAPI (single `server.py`), MongoDB (motor), JWT auth (bcrypt), Cloudinary signed uploads, Emergent LLM (Claude Sonnet 4.5).
- Frontend: React 19 + React Router 7, Tailwind + Shadcn UI, Recharts, Sonner toasts, Manrope/IBM Plex Sans fonts.
- Auth: JWT in localStorage. Role-based protected routes (`SUPER_ADMIN`, `CONTRACTOR`, `SUPERVISOR`, `CLIENT`).
- Multi-tenant: every doc carries `company_id`; queries scoped by role.

## V1 — Shipped (Feb 2026)
- Public: Landing (hero, features bento, dashboard preview, pricing, testimonials, FAQ, CTA), Pricing, About, Contact
- Auth: Login (with demo-fill panel), Contractor registration (admin-approval flow), credential generation on approval
- Contractor dashboard: 4 stat cards, site progress bar chart, expense pie chart, recent sites, activity feed
- Sites: list with filter, create dialog, detail page with tabs (Overview/Labour/Materials/Payments/Daily Reports/AI Insights)
- Labour: list + add, today's attendance marking with OT and advance
- Materials: list + add + inward/outward transactions, auto low-stock alerts, stock bar chart
- Payments: stat cards (received/expenses/profit/count) + transaction table
- Daily Reports: timeline with photo/video uploads via Cloudinary signed flow
- Notifications: list with read/unread, type icons
- Subscription: 3-tier plans with simulated upgrade (no real Razorpay)
- AI Insights: 4 kinds (material_estimate, progress_summary, delay_prediction, expense_analysis) via Claude Sonnet 4.5
- Super Admin: stats overview, revenue chart, applications approval (auto-generates username/password), contractors list (block/unblock), revenue page
- Supervisor: assigned sites view, attendance, daily reports
- Client: project portal (view sites, payments, daily reports)
- Seed data: admin, demo contractor + 3 sites + labour + materials + payments + report, supervisor, client

## V2 — Phase A Shipped (Feb 2026)
Backend:
- Labour Wallet (ledger + balance), recompute_wallet helper
- Attendance Automation: PRESENT/HALF/ABSENT status auto-credits EARNING + OT to ledger; idempotent re-saves; legacy `present: true` still works
- `/api/wallet/summary`, `/api/wallet/labour/{id}`, `/api/wallet/pay` (PAYMENT/ADVANCE/BONUS), mirrors payments
- Expenses module: `/api/expenses` + by_category & monthly report
- Vendors directory CRUD
- Construction Estimator engine + BOQ Generator (8 sections from foundation→plumbing)
- Audit Logs collection + admin endpoint, every write logs an entry
- UPI QR payment flow: `/api/payment/config` (upi_id=fk1571515@ybl, prices 0/499/1199), `/api/payment/request` (PENDING with UTR + screenshot), admin `/api/admin/payments/{approve|reject}` activates subscription
- Executive Dashboard endpoint with site profitability + 6-month cashflow trend
- `/api/subscription/upgrade` prices corrected to 499/1199

Frontend:
- Labour Wallet page + per-worker ledger detail + Pay dialog
- Expenses page with category pie + monthly bar charts
- Estimator (live formula) + BOQ viewer with print/PDF
- Vendors directory cards
- Subscription upgrade with UPI QR (generated client-side) + UTR + screenshot upload
- Admin: Pending UPI Payments approval, Audit Logs
- Executive Dashboard (contractor only)
- Sidebar reorganized into Overview / Operations / Finance / Planning / Account groups
- Dark mode toggle in header (dashboard-only)
- Attendance UI uses P/½/A status buttons + live earning preview

Test report: /app/test_reports/iteration_2.json — 21/21 backend tests PASSED (100%)

## V2 — Phase B (Not yet built)
AI Construction Assistant (chat), AI Cost Overrun, AI Consumption Analysis, AI Daily Report Gen, AI Client WhatsApp Update, PDF/Excel exports, Realtime notifications.

## V2 — Phase C (Not yet built)
Deeper subscription gating, white-label, mobile PWA shell, push notifications, advanced analytics.

## Test credentials
See `/app/memory/test_credentials.md`.
