import React from "react";
import { Outlet, NavLink, Link, useNavigate, useLocation } from "react-router-dom";
import { useAuth } from "@/lib/auth";
import { useTheme } from "@/lib/theme";
import Header from "@/components/layouts/Header/Header";
import Sidebar from "@/components/layouts/Sidebar/Sidebar"



export default function DashboardLayout() {
  const { user, logout } = useAuth();
  const { theme, toggle } = useTheme();
  const nav = useNavigate();
  const loc = useLocation();
  const [mobileOpen, setMobileOpen] = React.useState(false);

  React.useEffect(() => {
    if (user?.role !== "SUPER_ADMIN") return;
    let timer;
    const tick = async () => {
      try {
        const { data } = await import("@/lib/api").then(m => m.api.get("/admin/applications?status=PENDING"));
        setPendingApps(Array.isArray(data) ? data.length : 0);
      } catch { /* silent */ }
      timer = setTimeout(tick, 30000);
    };
    tick();
    return () => timer && clearTimeout(timer);
  }, [user?.role]);

  const role = user?.role;
  const isSuperAdmin = role === "SUPER_ADMIN";
  const closeMobile = () => setMobileOpen(false);

  // const contractorNav = (
  //   <>
  //     <NavGroup title="Overview">
  //       <NavItem to="/app/dashboard" icon={LayoutDashboard} label="Dashboard" />
  //       <NavItem to="/app/executive" icon={BarChart3} label="Executive" badge="PRO"
  //       />
  //     </NavGroup>
  //     <NavGroup title="Operations">
  //       <NavItem to="/app/sites" icon={Building2} label="Sites" />
  //       <NavItem to="/app/team" icon={Users} label="Team Management" />
  //       <NavItem to="/app/labour" icon={Users} label="Labour" />
  //       <NavItem to="/app/labour/wallet" icon={Wallet} label="Labour Wallet" />
  //       <NavItem to="/app/materials" icon={Package} label="Materials" />
  //       <NavItem to="/app/vendors" icon={Building} label="Vendors" />
  //       <NavItem to="/app/reports" icon={FileText} label="Daily Reports" />
  //     </NavGroup>
  //     <NavGroup title="Finance">
  //       <NavItem to="/app/payments" icon={BadgeIndianRupee} label="Payments" />
  //       <NavItem to="/app/expenses" icon={Receipt} label="Expenses" />
  //     </NavGroup>
  //     <NavGroup title="Planning">
  //       <NavItem to="/app/estimates" icon={Calculator} label="Estimator" />
  //       <NavItem to="/app/boq" icon={FileText} label="BOQ" />
  //       <NavItem
  //         to="/app/maps"
  //         icon={Map}
  //         label="Design Studio"
  //       />
  //     </NavGroup>
  //     <NavGroup title="Account">
  //       <NavItem to="/app/notifications" icon={Bell} label="Notifications" />
  //       <NavItem to="/app/subscription" icon={CreditCard} label="Subscription" />
  //       <NavItem to="/app/branding" icon={Building} label="Company Branding" />
  //       <NavItem to="/app/settings" icon={SettingsIcon} label="Settings" />
  //     </NavGroup>
  //   </>
  // );

  // const supervisorNav = (
  //   <>
  //     <NavItem to="/app/dashboard" icon={LayoutDashboard} label="Dashboard" />
  //     <NavItem to="/app/sites" icon={Building2} label="My Sites" />
  //     <NavItem to="/app/labour" icon={Users} label="Attendance" />
  //     <NavItem to="/app/labour/wallet" icon={Wallet} label="Labour Wallet" />
  //     <NavItem to="/app/materials" icon={Package} label="Materials" />
  //     <NavItem to="/app/expenses" icon={Receipt} label="Expenses" />
  //     <NavItem to="/app/reports" icon={FileText} label="Daily Reports" />
  //     <NavItem to="/app/notifications" icon={Bell} label="Notifications" />
  //     <NavItem to="/app/settings" icon={SettingsIcon} label="Settings" />
  //   </>
  // );

  // const clientNav = (
  //   <>
  //     <NavItem to="/app/dashboard" icon={LayoutDashboard} label="Dashboard" />
  //     <NavItem to="/app/sites" icon={Building2} label="My Project" />
  //     <NavItem to="/app/payments" icon={Wallet} label="Payments" />
  //     <NavItem to="/app/reports" icon={FileText} label="Updates" />
  //     <NavItem to="/app/notifications" icon={Bell} label="Notifications" />
  //     <NavItem to="/app/settings" icon={SettingsIcon} label="Settings" />
  //   </>
  // );

  // const adminNav = (
  //   <NavGroup title="Platform">
  //     <NavItem to="/app/admin" icon={LayoutDashboard} label="Overview" end />
  //     <NavItem to="/app/admin/applications" icon={Briefcase} label="Applications" badge={pendingApps > 0 ? pendingApps : null} />
  //     <NavItem to="/app/admin/contractors" icon={Users} label="Contractors" />
  //     <NavItem to="/app/admin/supervisors" icon={Users} label="Supervisors" />
  //     <NavItem to="/app/admin/subscriptions" icon={CreditCard} label="Subscriptions" />
  //     <NavItem to="/app/admin/payments" icon={BadgeIndianRupee} label="UPI Payments" />
  //     <NavItem to="/app/admin/revenue" icon={BarChart3} label="Analytics" />
  //     <NavItem to="/app/admin/audit" icon={Activity} label="Audit Logs" />
  //     <NavItem to="/app/notifications" icon={Bell} label="Notifications" />
  //     <NavItem to="/app/settings" icon={SettingsIcon} label="Settings" />
  //   </NavGroup>
  // );


  return (
    <div className={`min-h-screen flex ${theme === "dark" ? "ss-dark" : ""}`}>
      {/* Desktop sidebar */}
      <div className="hidden lg:flex">

        <Sidebar
          user={user}
          role={user?.role}
          logout={logout}
          nav={nav}
          closeMobile={() => setMobileOpen(false)}
        />

      </div>

      {/* Mobile sidebar drawer */}
      {mobileOpen && (
        <div className="fixed inset-0 z-50 lg:hidden">
          <div className="absolute inset-0 bg-black/60" onClick={closeMobile} />
          <div className="absolute left-0 top-0 bottom-0"><Sidebar {...sidebarProps} /></div>
        </div>
      )}

      <div className="flex-1 flex flex-col">

        <Header

          user={user}

          theme={theme}

          toggle={toggle}

          nav={nav}

          logout={logout}

        />
        <main className="flex-1 p-4 sm:p-6 lg:p-8">
          <Outlet />
        </main>
      </div>
    </div>
  );
}
