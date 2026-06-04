"""Site Seva Pro V2 Phase A backend tests."""
import os
import time
import pytest
import requests

BASE_URL = os.environ.get("REACT_APP_BACKEND_URL", "").rstrip("/") or "https://contractor-dashboard-13.preview.emergentagent.com"
API = f"{BASE_URL}/api"


# ---------------- Fixtures ----------------
@pytest.fixture(scope="session")
def s():
    return requests.Session()


def _login(s, email, pw):
    r = s.post(f"{API}/auth/login", json={"email": email, "password": pw}, timeout=20)
    assert r.status_code == 200, f"login failed for {email}: {r.status_code} {r.text}"
    return r.json()["token"]


@pytest.fixture(scope="session")
def admin_token(s):
    return _login(s, "admin@siteseva.pro", "Admin@SiteSeva2026")


@pytest.fixture(scope="session")
def contractor_token(s):
    return _login(s, "contractor@demo.com", "Contractor@2026")


@pytest.fixture(scope="session")
def supervisor_token(s):
    return _login(s, "supervisor@demo.com", "Supervisor@2026")


@pytest.fixture(scope="session")
def client_token(s):
    return _login(s, "client@demo.com", "Client@2026")


def _h(t):
    return {"Authorization": f"Bearer {t}"}


@pytest.fixture(scope="session")
def contractor_ctx(s, contractor_token):
    sites = s.get(f"{API}/sites", headers=_h(contractor_token), timeout=20).json()
    assert isinstance(sites, list) and len(sites) >= 1
    labour = s.get(f"{API}/labour", headers=_h(contractor_token), timeout=20).json()
    # Reorder sites so that the site with seeded labour is first
    if labour:
        labour_site_ids = {l["site_id"] for l in labour}
        sites = sorted(sites, key=lambda x: 0 if x["id"] in labour_site_ids else 1)
    return {"sites": sites, "labour": labour}


# ---------------- Auth / Config ----------------
class TestAuthAndConfig:
    def test_contractor_login(self, contractor_token):
        assert contractor_token and len(contractor_token) > 20

    def test_payment_config(self, s, contractor_token):
        r = s.get(f"{API}/payment/config", headers=_h(contractor_token), timeout=20)
        assert r.status_code == 200
        d = r.json()
        assert d["upi_id"] == "fk1571515@ybl"
        assert d["prices"] == {"FREE": 0, "PREMIUM": 499, "ENTERPRISE": 1199}


# ---------------- Attendance + Wallet ----------------
class TestAttendanceWallet:
    def test_attendance_status_creates_earning(self, s, contractor_token, contractor_ctx):
        site = contractor_ctx["sites"][0]
        labour = [l for l in contractor_ctx["labour"] if l["site_id"] == site["id"]]
        assert len(labour) >= 2, "Need seeded labour on first site"
        date = "2026-01-10"
        entries = [
            {"labour_id": labour[0]["id"], "status": "PRESENT", "overtime_hours": 2, "advance": 0},
            {"labour_id": labour[1]["id"], "status": "HALF", "overtime_hours": 0, "advance": 0},
        ]
        if len(labour) >= 3:
            entries.append({"labour_id": labour[2]["id"], "status": "ABSENT"})
        r = s.post(f"{API}/attendance",
                   json={"site_id": site["id"], "date": date, "entries": entries},
                   headers=_h(contractor_token), timeout=20)
        assert r.status_code == 200, r.text

        # Check wallet detail for labour[0] — PRESENT wage 800 + OT 2*(800/8)=200 → 1000 earning expected
        r2 = s.get(f"{API}/wallet/labour/{labour[0]['id']}", headers=_h(contractor_token), timeout=20)
        assert r2.status_code == 200, r2.text
        wd = r2.json()
        # The requirement says attendance must auto-credit. Verify ledger has EARNING for the date.
        earnings_for_date = [e for e in wd["ledger"] if e.get("date") == date and e.get("type") == "EARNING"]
        assert earnings_for_date, f"No EARNING ledger created for PRESENT attendance. Ledger: {wd['ledger']}"
        expected = labour[0]["daily_wage"] + 2 * (labour[0]["daily_wage"] / 8)
        assert abs(earnings_for_date[0]["amount"] - expected) < 0.01, \
            f"PRESENT+OT earning {earnings_for_date[0]['amount']} != {expected}"

        # HALF labour should have EARNING = wage/2
        r3 = s.get(f"{API}/wallet/labour/{labour[1]['id']}", headers=_h(contractor_token), timeout=20).json()
        half_earn = [e for e in r3["ledger"] if e.get("date") == date and e.get("type") == "EARNING"]
        assert half_earn, "HALF status did not credit earning"
        assert abs(half_earn[0]["amount"] - labour[1]["daily_wage"] * 0.5) < 0.01

    def test_attendance_idempotent_reposting(self, s, contractor_token, contractor_ctx):
        site = contractor_ctx["sites"][0]
        labour = [l for l in contractor_ctx["labour"] if l["site_id"] == site["id"]]
        date = "2026-01-11"
        entries = [{"labour_id": labour[0]["id"], "status": "PRESENT"}]
        s.post(f"{API}/attendance", json={"site_id": site["id"], "date": date, "entries": entries},
               headers=_h(contractor_token), timeout=20)
        s.post(f"{API}/attendance", json={"site_id": site["id"], "date": date, "entries": entries},
               headers=_h(contractor_token), timeout=20)
        wd = s.get(f"{API}/wallet/labour/{labour[0]['id']}", headers=_h(contractor_token), timeout=20).json()
        earnings_for_date = [e for e in wd["ledger"] if e.get("date") == date and e.get("type") == "EARNING"]
        assert len(earnings_for_date) <= 1, f"Re-posting created duplicate EARNINGs ({len(earnings_for_date)})"

    def test_legacy_present_true(self, s, contractor_token, contractor_ctx):
        site = contractor_ctx["sites"][0]
        labour = [l for l in contractor_ctx["labour"] if l["site_id"] == site["id"]][0]
        date = "2026-01-12"
        entries = [{"labour_id": labour["id"], "present": True}]
        r = s.post(f"{API}/attendance", json={"site_id": site["id"], "date": date, "entries": entries},
                   headers=_h(contractor_token), timeout=20)
        assert r.status_code == 200
        wd = s.get(f"{API}/wallet/labour/{labour['id']}", headers=_h(contractor_token), timeout=20).json()
        earn = [e for e in wd["ledger"] if e.get("date") == date and e.get("type") == "EARNING"]
        assert earn, "Legacy present:true did not auto-credit wallet"

    def test_wallet_summary(self, s, contractor_token):
        r = s.get(f"{API}/wallet/summary", headers=_h(contractor_token), timeout=20)
        assert r.status_code == 200
        d = r.json()
        for k in ("total_earned", "total_paid", "total_balance", "rows"):
            assert k in d
        assert isinstance(d["rows"], list)

    def test_wallet_pay(self, s, contractor_token, contractor_ctx):
        labour = contractor_ctx["labour"][0]
        before = s.get(f"{API}/wallet/labour/{labour['id']}", headers=_h(contractor_token), timeout=20).json()
        prev_paid = before["wallet"].get("total_paid", 0)
        r = s.post(f"{API}/wallet/pay",
                   json={"labour_id": labour["id"], "amount": 250, "type": "PAYMENT", "note": "TEST_pay"},
                   headers=_h(contractor_token), timeout=20)
        assert r.status_code == 200, r.text
        snap = r.json()["wallet"]
        assert abs(snap["total_paid"] - (prev_paid + 250)) < 0.01

        # mirrored to payments
        pays = s.get(f"{API}/payments", headers=_h(contractor_token), timeout=20).json()
        assert any(p.get("type") == "LABOUR" and p.get("party") == labour["name"] for p in pays)


# ---------------- Expenses ----------------
class TestExpenses:
    def test_create_list_report(self, s, contractor_token, contractor_ctx):
        site = contractor_ctx["sites"][0]
        r = s.post(f"{API}/expenses",
                   json={"site_id": site["id"], "category": "FUEL", "amount": 1500,
                         "description": "TEST_diesel", "date": "2026-01-15"},
                   headers=_h(contractor_token), timeout=20)
        assert r.status_code == 200, r.text
        r2 = s.get(f"{API}/expenses", headers=_h(contractor_token), timeout=20)
        assert r2.status_code == 200 and any(e["description"] == "TEST_diesel" for e in r2.json())
        rep = s.get(f"{API}/expenses/report", headers=_h(contractor_token), timeout=20).json()
        assert "by_category" in rep and "monthly" in rep


# ---------------- Vendors ----------------
class TestVendors:
    def test_crud(self, s, contractor_token):
        r = s.post(f"{API}/vendors", json={"name": "TEST_Vendor", "contact": "9999999999"},
                   headers=_h(contractor_token), timeout=20)
        assert r.status_code == 200
        vid = r.json()["id"]
        lst = s.get(f"{API}/vendors", headers=_h(contractor_token), timeout=20).json()
        assert any(v["id"] == vid for v in lst)
        d = s.delete(f"{API}/vendors/{vid}", headers=_h(contractor_token), timeout=20)
        assert d.status_code == 200


# ---------------- Estimator + BOQ ----------------
class TestEstimateBOQ:
    def test_estimate_formulas(self, s, contractor_token):
        body = {"name": "TEST_Est", "plot_area_sqft": 1000, "floors": 2,
                "construction_type": "RESIDENTIAL", "quality": "STANDARD"}
        r = s.post(f"{API}/estimates", json=body, headers=_h(contractor_token), timeout=20)
        assert r.status_code == 200, r.text
        e = r.json()
        builtup = 2000
        assert e["builtup_sqft"] == builtup
        m = e["materials"]
        assert m["cement_bags"] == 800.0
        assert m["steel_kg"] == 8000.0
        assert m["sand_cft"] == 1700.0
        assert m["aggregate_cft"] == 1300.0
        assert m["bricks_pcs"] == 16000.0
        assert e["rate_per_sqft"] == 1800 * 1.0
        assert e["total"] == builtup * 1800
        TestEstimateBOQ.eid = e["id"]
        TestEstimateBOQ.builtup = builtup

    def test_estimate_list_get(self, s, contractor_token):
        lst = s.get(f"{API}/estimates", headers=_h(contractor_token), timeout=20).json()
        assert isinstance(lst, list) and len(lst) >= 1
        got = s.get(f"{API}/estimates/{TestEstimateBOQ.eid}", headers=_h(contractor_token), timeout=20)
        assert got.status_code == 200

    def test_boq_generate(self, s, contractor_token):
        r = s.post(f"{API}/boq/generate",
                   json={"estimate_id": TestEstimateBOQ.eid, "name": "TEST_BOQ"},
                   headers=_h(contractor_token), timeout=20)
        assert r.status_code == 200, r.text
        b = r.json()
        names = {sec["name"] for sec in b["sections"]}
        for need in ["Foundation", "RCC Work", "Brickwork", "Plaster", "Flooring", "Painting", "Electrical", "Plumbing"]:
            assert need in names
        for sec in b["sections"]:
            for it in sec["items"]:
                for k in ("desc", "unit", "qty", "rate", "amount"):
                    assert k in it
        assert b["total"] > 0


# ---------------- Payment requests ----------------
class TestPaymentRequests:
    def test_create_and_admin_approve(self, s, contractor_token, admin_token):
        r = s.post(f"{API}/payment/request",
                   json={"plan": "PREMIUM", "utr": "TESTUTR123456", "note": "TEST"},
                   headers=_h(contractor_token), timeout=20)
        assert r.status_code == 200, r.text
        pid = r.json()["id"]
        assert r.json()["amount"] == 499
        assert r.json()["status"] == "PENDING"

        my = s.get(f"{API}/payment/my", headers=_h(contractor_token), timeout=20).json()
        assert any(p["id"] == pid for p in my)

        adm = s.get(f"{API}/admin/payments", headers=_h(admin_token), timeout=20)
        assert adm.status_code == 200 and any(p["id"] == pid for p in adm.json())

        ap = s.post(f"{API}/admin/payments/{pid}/approve", headers=_h(admin_token), timeout=20)
        assert ap.status_code == 200

        # 2nd request for reject path
        r2 = s.post(f"{API}/payment/request",
                    json={"plan": "ENTERPRISE", "utr": "TESTUTR999", "note": "TEST"},
                    headers=_h(contractor_token), timeout=20)
        pid2 = r2.json()["id"]
        rj = s.post(f"{API}/admin/payments/{pid2}/reject?reason=invalid", headers=_h(admin_token), timeout=20)
        assert rj.status_code == 200

    def test_non_admin_cannot_access_admin_payments(self, s, contractor_token):
        r = s.get(f"{API}/admin/payments", headers=_h(contractor_token), timeout=20)
        assert r.status_code == 403


# ---------------- Audit ----------------
class TestAudit:
    def test_audit_list(self, s, admin_token):
        r = s.get(f"{API}/admin/audit?limit=200", headers=_h(admin_token), timeout=20)
        assert r.status_code == 200
        logs = r.json()
        entities = {l.get("entity") for l in logs}
        # At minimum estimate/vendor/expense and payment_request should be present from earlier tests
        assert "estimate" in entities or "expense" in entities or "vendor" in entities
        assert "payment_request" in entities


# ---------------- Executive Dashboard ----------------
class TestExecutiveDashboard:
    def test_executive(self, s, contractor_token):
        r = s.get(f"{API}/dashboard/executive", headers=_h(contractor_token), timeout=20)
        assert r.status_code == 200
        d = r.json()
        for k in ("active_sites", "total_sites", "supervisors", "total_labour", "labour_cost",
                  "material_cost", "expenses", "received", "pending", "profit",
                  "site_profitability", "trend"):
            assert k in d, f"missing {k}"
        assert isinstance(d["site_profitability"], list)
        assert isinstance(d["trend"], list)


# ---------------- Role isolation ----------------
class TestRoleIsolation:
    def test_supervisor_wallet_summary(self, s, supervisor_token):
        r = s.get(f"{API}/wallet/summary", headers=_h(supervisor_token), timeout=20)
        assert r.status_code == 200

    def test_client_forbidden_wallet(self, s, client_token):
        r = s.get(f"{API}/wallet/summary", headers=_h(client_token), timeout=20)
        assert r.status_code == 403

    def test_client_forbidden_expenses_create(self, s, client_token, contractor_ctx):
        site = contractor_ctx["sites"][0]
        r = s.post(f"{API}/expenses",
                   json={"site_id": site["id"], "category": "FUEL", "amount": 100,
                         "description": "x", "date": "2026-01-01"},
                   headers=_h(client_token), timeout=20)
        assert r.status_code == 403

    def test_client_forbidden_estimates(self, s, client_token):
        r = s.post(f"{API}/estimates",
                   json={"name": "x", "plot_area_sqft": 100, "floors": 1},
                   headers=_h(client_token), timeout=20)
        assert r.status_code == 403


# ---------------- Plan enforcement ----------------
class TestPlanEnforcement:
    def test_free_plan_blocks_second_site(self, s, admin_token):
        # Create a fresh contractor application → approve → FREE plan
        ts = int(time.time())
        email = f"freecon_{ts}@test.com"
        app_payload = {
            "company_name": f"TEST FreeCo {ts}", "owner_name": "Free Owner",
            "mobile": "9000000000", "email": email,
            "office_address": "addr", "city": "Pune", "state": "MH",
            "active_projects": 0, "employee_count": 1,
        }
        ap = s.post(f"{API}/auth/register", json=app_payload, timeout=20)
        assert ap.status_code == 200, ap.text
        app_id = ap.json()["id"]
        approve = s.post(f"{API}/admin/applications/{app_id}/approve", headers=_h(admin_token), timeout=20).json()
        creds_user, creds_pw = approve["email"], approve["password"]
        tok = _login(s, creds_user, creds_pw)
        site_body = {
            "name": "S1", "client_name": "c", "location": "x", "budget": 1,
            "start_date": "2026-01-01", "end_date": "2026-02-01", "status": "ACTIVE", "progress": 0,
        }
        r1 = s.post(f"{API}/sites", json=site_body, headers=_h(tok), timeout=20)
        assert r1.status_code == 200
        r2 = s.post(f"{API}/sites", json={**site_body, "name": "S2"}, headers=_h(tok), timeout=20)
        assert r2.status_code == 402, f"Expected 402, got {r2.status_code}"
