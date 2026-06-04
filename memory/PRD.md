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

## V2 — Planned (next iteration, NOT yet built)
Major scope expansion requested by user. See V2_PLAN.md for full plan.

P0 (must in v2 phase 1):
- Labour Wallet System (ledger, earnings, payments, balance)
- Attendance Automation (auto-earning on present/half/OT)
- Construction Estimation Engine + BOQ Generator
- AI Construction Assistant (chat)
- AI Cost Overrun Prediction + Material Consumption Analysis
- Audit Logs
- Expense module split from Payments (Fuel/Transport/Equipment/Food/Misc)
- Vendor + Invoice tracking
- Advanced executive dashboard
- Dark mode

P1 (v2 phase 2):
- AI Daily Report Generator + AI Client WhatsApp Update
- Weekly/Monthly aggregated reports + PDF export
- Realtime notifications (SSE / polling)
- Subscription feature gating (deeper)
- Advanced analytics dashboard (profitability, trends, projections)

P2 (v2 phase 3):
- White-label branding (Enterprise)
- Mobile-optimised PWA shell
- Push notifications

## Test credentials
See `/app/memory/test_credentials.md`.
