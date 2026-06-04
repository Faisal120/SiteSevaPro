"""Site Seva Pro V2 — Super Admin all-access + new estimator schema + plan prices tests."""
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
    assert r.status_code == 200, f"login failed {email}: {r.status_code} {r.text}"
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


# ---------------- 1. Super Admin /api/auth/me ----------------
class TestSuperAdminMe:
    def test_me_has_company_and_enterprise(self, s, admin_token):
        r = s.get(f"{API}/auth/me", headers=_h(admin_token), timeout=20)
        assert r.status_code == 200, r.text
        d = r.json()
        assert d["role"] == "SUPER_ADMIN"
        assert d.get("company_id"), f"SUPER_ADMIN missing company_id: {d}"
        assert d.get("plan") == "ENTERPRISE", f"Expected ENTERPRISE, got {d.get('plan')}"


# ---------------- 2. Super Admin can hit ALL contractor endpoints ----------------
class TestSuperAdminAllAccess:
    def test_sites_get(self, s, admin_token):
        r = s.get(f"{API}/sites", headers=_h(admin_token), timeout=20)
        assert r.status_code == 200, r.text
        assert isinstance(r.json(), list)

    def test_labour_get(self, s, admin_token):
        r = s.get(f"{API}/labour", headers=_h(admin_token), timeout=20)
        assert r.status_code == 200, r.text

    def test_wallet_summary(self, s, admin_token):
        r = s.get(f"{API}/wallet/summary", headers=_h(admin_token), timeout=20)
        assert r.status_code == 200, r.text
        for k in ("total_earned", "total_paid", "total_balance", "rows"):
            assert k in r.json()

    def test_wallet_labour_detail(self, s, admin_token, contractor_token):
        # need a labour id — fetch via contractor
        labour = s.get(f"{API}/labour", headers=_h(contractor_token), timeout=20).json()
        assert labour, "No seeded labour"
        lid = labour[0]["id"]
        r = s.get(f"{API}/wallet/labour/{lid}", headers=_h(admin_token), timeout=20)
        assert r.status_code == 200, r.text

    def test_wallet_pay(self, s, admin_token, contractor_token):
        labour = s.get(f"{API}/labour", headers=_h(contractor_token), timeout=20).json()
        lid = labour[0]["id"]
        r = s.post(f"{API}/wallet/pay",
                   json={"labour_id": lid, "amount": 50, "type": "PAYMENT", "note": "TEST_admin_pay"},
                   headers=_h(admin_token), timeout=20)
        assert r.status_code == 200, r.text

    def test_materials(self, s, admin_token):
        r = s.get(f"{API}/materials", headers=_h(admin_token), timeout=20)
        assert r.status_code == 200, r.text

    def test_material_txns(self, s, admin_token):
        r = s.get(f"{API}/material-txns", headers=_h(admin_token), timeout=20)
        assert r.status_code == 200, r.text

    def test_vendors(self, s, admin_token):
        r = s.get(f"{API}/vendors", headers=_h(admin_token), timeout=20)
        assert r.status_code == 200, r.text

    def test_payments(self, s, admin_token):
        r = s.get(f"{API}/payments", headers=_h(admin_token), timeout=20)
        assert r.status_code == 200, r.text

    def test_expenses(self, s, admin_token):
        r = s.get(f"{API}/expenses", headers=_h(admin_token), timeout=20)
        assert r.status_code == 200, r.text

    def test_estimates(self, s, admin_token):
        r = s.get(f"{API}/estimates", headers=_h(admin_token), timeout=20)
        assert r.status_code == 200, r.text

    def test_dashboard_contractor(self, s, admin_token):
        r = s.get(f"{API}/dashboard/contractor", headers=_h(admin_token), timeout=20)
        assert r.status_code == 200, r.text

    def test_dashboard_executive(self, s, admin_token):
        r = s.get(f"{API}/dashboard/executive", headers=_h(admin_token), timeout=20)
        assert r.status_code == 200, r.text

    def test_estimate_post(self, s, admin_token):
        body = {"name": "TEST_AdminEst", "plot_area_sqft": 1000, "floors": 2,
                "construction_type": "RESIDENTIAL", "quality": "STANDARD", "budget": 3600000}
        r = s.post(f"{API}/estimates", json=body, headers=_h(admin_token), timeout=20)
        assert r.status_code == 200, r.text

    def test_boq_generate(self, s, admin_token):
        r = s.post(f"{API}/boq/generate",
                   json={"name": "TEST_AdminBOQ", "builtup_sqft": 1000},
                   headers=_h(admin_token), timeout=20)
        assert r.status_code == 200, r.text


# ---------------- 3. Super Admin retains admin endpoints ----------------
class TestSuperAdminEndpoints:
    def test_admin_stats(self, s, admin_token):
        r = s.get(f"{API}/admin/stats", headers=_h(admin_token), timeout=20)
        assert r.status_code == 200

    def test_admin_applications(self, s, admin_token):
        r = s.get(f"{API}/admin/applications", headers=_h(admin_token), timeout=20)
        assert r.status_code == 200

    def test_admin_contractors(self, s, admin_token):
        r = s.get(f"{API}/admin/contractors", headers=_h(admin_token), timeout=20)
        assert r.status_code == 200

    def test_admin_payments(self, s, admin_token):
        r = s.get(f"{API}/admin/payments", headers=_h(admin_token), timeout=20)
        assert r.status_code == 200

    def test_admin_audit(self, s, admin_token):
        r = s.get(f"{API}/admin/audit?limit=10", headers=_h(admin_token), timeout=20)
        assert r.status_code == 200


# ---------------- 4. Role isolation guards still hold ----------------
class TestRoleGuards:
    def test_client_forbidden_wallet(self, s, client_token):
        r = s.get(f"{API}/wallet/summary", headers=_h(client_token), timeout=20)
        assert r.status_code == 403

    def test_client_forbidden_estimates(self, s, client_token):
        r = s.post(f"{API}/estimates",
                   json={"name": "x", "plot_area_sqft": 100, "floors": 1, "budget": 100000},
                   headers=_h(client_token), timeout=20)
        assert r.status_code == 403

    def test_client_forbidden_admin(self, s, client_token):
        r = s.get(f"{API}/admin/stats", headers=_h(client_token), timeout=20)
        assert r.status_code == 403

    def test_supervisor_wallet_ok(self, s, supervisor_token):
        r = s.get(f"{API}/wallet/summary", headers=_h(supervisor_token), timeout=20)
        assert r.status_code == 200

    def test_supervisor_expenses_ok(self, s, supervisor_token, contractor_token):
        sites = s.get(f"{API}/sites", headers=_h(contractor_token), timeout=20).json()
        # Supervisor needs site assigned; use first one. POST may still 403 if not assigned, so test GET first.
        r = s.get(f"{API}/expenses", headers=_h(supervisor_token), timeout=20)
        assert r.status_code == 200

    def test_supervisor_attendance_ok(self, s, supervisor_token, contractor_token):
        # GET attendance requires site_id query param
        sites = s.get(f"{API}/sites", headers=_h(contractor_token), timeout=20).json()
        site_id = sites[0]["id"]
        r = s.get(f"{API}/attendance?site_id={site_id}", headers=_h(supervisor_token), timeout=20)
        assert r.status_code == 200, r.text

    def test_supervisor_forbidden_admin(self, s, supervisor_token):
        r = s.get(f"{API}/admin/stats", headers=_h(supervisor_token), timeout=20)
        assert r.status_code == 403

    def test_supervisor_forbidden_estimates(self, s, supervisor_token):
        r = s.post(f"{API}/estimates",
                   json={"name": "x", "plot_area_sqft": 100, "floors": 1, "budget": 100000},
                   headers=_h(supervisor_token), timeout=20)
        assert r.status_code == 403


# ---------------- 5. New estimator schema ----------------
class TestEstimatorSchema:
    def test_premium_semi_commercial_with_basement(self, s, contractor_token):
        body = {"name": "TEST_PremSC", "plot_area_sqft": 1000, "floors": 2,
                "basement": True, "construction_type": "SEMI_COMMERCIAL",
                "quality": "PREMIUM", "budget": 5000000}
        r = s.post(f"{API}/estimates", json=body, headers=_h(contractor_token), timeout=20)
        assert r.status_code == 200, r.text
        e = r.json()
        # builtup = 1000 * (2 + 0.85) = 2850
        assert e["builtup_sqft"] == 2850.0, f"builtup_sqft={e['builtup_sqft']}"
        # type_factor for SEMI_COMMERCIAL = 1.08
        assert e["type_factor"] == 1.08
        # Quality band recorded
        assert e["quality_band"] == "PREMIUM"
        # PREMIUM mix = 60/26/14
        total = 5000000
        assert abs(e["material_cost"] - total * 0.60) < 1, f"material_cost={e['material_cost']}"
        assert abs(e["labour_cost"] - total * 0.26) < 1, f"labour_cost={e['labour_cost']}"
        assert abs(e["overhead"] - total * 0.14) < 1, f"overhead={e['overhead']}"
        # Basement: cement_bags = builtup * 0.4 * 1.06; steel_kg = builtup * 4 * 1.10
        expected_cement = round(2850 * 0.4 * 1.06, 2)
        expected_steel = round(2850 * 4.0 * 1.10, 2)
        assert e["materials"]["cement_bags"] == expected_cement, \
            f"cement={e['materials']['cement_bags']}, expected={expected_cement}"
        assert e["materials"]["steel_kg"] == expected_steel, \
            f"steel={e['materials']['steel_kg']}, expected={expected_steel}"

    def test_basement_bumps_cement_steel(self, s, contractor_token):
        # Compare without basement vs with basement at same params
        base = {"name": "TEST_NoBase", "plot_area_sqft": 1000, "floors": 1,
                "basement": False, "construction_type": "RESIDENTIAL",
                "quality": "STANDARD", "budget": 1800000}
        r1 = s.post(f"{API}/estimates", json=base, headers=_h(contractor_token), timeout=20)
        assert r1.status_code == 200
        e1 = r1.json()
        # With basement
        r2 = s.post(f"{API}/estimates", json={**base, "name": "TEST_WithBase", "basement": True},
                    headers=_h(contractor_token), timeout=20)
        assert r2.status_code == 200
        e2 = r2.json()
        # per-builtup cement rate: e1 cement = 1000*0.4 = 400; e2 cement per builtup = 0.4*1.06 ≈ 0.424
        cement_per_sqft_1 = e1["materials"]["cement_bags"] / e1["builtup_sqft"]
        cement_per_sqft_2 = e2["materials"]["cement_bags"] / e2["builtup_sqft"]
        assert abs(cement_per_sqft_2 / cement_per_sqft_1 - 1.06) < 0.001
        steel_per_sqft_1 = e1["materials"]["steel_kg"] / e1["builtup_sqft"]
        steel_per_sqft_2 = e2["materials"]["steel_kg"] / e2["builtup_sqft"]
        assert abs(steel_per_sqft_2 / steel_per_sqft_1 - 1.10) < 0.001

    def test_budget_zero_rejected(self, s, contractor_token):
        r = s.post(f"{API}/estimates",
                   json={"name": "TEST_BadBudget", "plot_area_sqft": 1000, "floors": 1,
                         "quality": "STANDARD", "budget": 0},
                   headers=_h(contractor_token), timeout=20)
        assert r.status_code == 400, f"Expected 400, got {r.status_code}: {r.text}"

    def test_plot_zero_rejected(self, s, contractor_token):
        r = s.post(f"{API}/estimates",
                   json={"name": "TEST_BadPlot", "plot_area_sqft": 0, "floors": 1,
                         "quality": "STANDARD", "budget": 100000},
                   headers=_h(contractor_token), timeout=20)
        assert r.status_code == 400


# ---------------- 6. Payment config prices ----------------
class TestPaymentPrices:
    def test_payment_config_prices(self, s, contractor_token):
        r = s.get(f"{API}/payment/config", headers=_h(contractor_token), timeout=20)
        assert r.status_code == 200
        d = r.json()
        assert d["prices"]["PREMIUM"] == 899, f"PREMIUM={d['prices']}"
        assert d["prices"]["ENTERPRISE"] == 1899
        assert d["prices"]["FREE"] == 0


# ---------------- 7. FREE plan limit: skipped for SUPER_ADMIN, enforced for new CONTRACTOR ----------------
class TestPlanEnforcement:
    def test_super_admin_unlimited_sites(self, s, admin_token):
        # Super admin already has multiple seeded sites; create 2 more — both must succeed.
        site_body = {
            "name": f"TEST_AdminSite_{int(time.time())}", "client_name": "c", "location": "x",
            "budget": 1, "start_date": "2026-01-01", "end_date": "2026-02-01",
            "status": "ACTIVE", "progress": 0,
        }
        r1 = s.post(f"{API}/sites", json=site_body, headers=_h(admin_token), timeout=20)
        assert r1.status_code == 200, r1.text
        r2 = s.post(f"{API}/sites",
                    json={**site_body, "name": f"TEST_AdminSite2_{int(time.time())}"},
                    headers=_h(admin_token), timeout=20)
        assert r2.status_code == 200, f"SUPER_ADMIN second site blocked: {r2.status_code} {r2.text}"

    def test_free_contractor_blocked_at_second_site(self, s, admin_token):
        ts = int(time.time())
        email = f"freec_{ts}@test.com"
        ap = s.post(f"{API}/auth/register", json={
            "company_name": f"TEST_FreeCo_{ts}", "owner_name": "Free",
            "mobile": "9000000000", "email": email,
            "office_address": "addr", "city": "Pune", "state": "MH",
            "active_projects": 0, "employee_count": 1,
        }, timeout=20)
        assert ap.status_code == 200
        app_id = ap.json()["id"]
        approve = s.post(f"{API}/admin/applications/{app_id}/approve",
                         headers=_h(admin_token), timeout=20).json()
        tok = _login(s, approve["email"], approve["password"])
        body = {"name": "S1", "client_name": "c", "location": "x", "budget": 1,
                "start_date": "2026-01-01", "end_date": "2026-02-01",
                "status": "ACTIVE", "progress": 0}
        r1 = s.post(f"{API}/sites", json=body, headers=_h(tok), timeout=20)
        assert r1.status_code == 200
        r2 = s.post(f"{API}/sites", json={**body, "name": "S2"},
                    headers=_h(tok), timeout=20)
        assert r2.status_code == 402, f"Expected 402, got {r2.status_code}"
