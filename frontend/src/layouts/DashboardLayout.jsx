import React from "react";
import { Outlet, NavLink, Link, useNavigate, useLocation } from "react-router-dom";
import {
  LayoutDashboard, Building2, Users, Package, Wallet, FileText, Bell, CreditCard, Settings as SettingsIcon,
  HardHat, LogOut, Shield, Briefcase, BarChart3, ChevronDown, Search, Calculator, Receipt, Building,
  Activity, BadgeIndianRupee, Sun, Moon, Menu, X,
} from "lucide-react";
import { useAuth } from "@/lib/auth";
import { useTheme } from "@/lib/theme";
import { Avatar, AvatarFallback } from "@/components/ui/avatar";
import {
  DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuLabel, DropdownMenuSeparator, DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";

function NavItem({ to, icon: Icon, label, end, badge }) {
  return (
    <NavLink
      to={to}
      end={end}
      className={({ isActive }) => `ss-sidebar-link ${isActive ? "ss-sidebar-link-active" : ""}`}
      data-testid={`sidebar-${label.toLowerCase().replace(/[^a-z0-9]+/g, "-")}`}
    >
      <Icon className="h-4 w-4" />
      <span className="flex-1">{label}</span>
      {badge && <span className="ss-chip bg-[#F97316] text-white text-[10px] px-1.5 py-0.5">{badge}</span>}
    </NavLink>
  );
}

function NavGroup({ title, children }) {
  return (
    <div className="mt-3">
      <div className="px-3 py-1 text-[10px] font-bold uppercase tracking-[0.18em] text-gray-500">{title}</div>
      <div className="flex flex-col gap-0.5 mt-1">{children}</div>
    </div>
  );
}

export default function DashboardLayout() {
  const { user, logout } = useAuth();
  const { theme, toggle } = useTheme();
  const nav = useNavigate();
  const loc = useLocation();
  const [mobileOpen, setMobileOpen] = React.useState(false);
  const [pendingApps, setPendingApps] = React.useState(0);

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

  const contractorNav = (
    <>
      <NavGroup title="Overview">
        <NavItem to="/app/dashboard" icon={LayoutDashboard} label="Dashboard" />
        <NavItem to="/app/executive" icon={BarChart3} label="Executive" badge="PRO"
        />
      </NavGroup>
      <NavGroup title="Operations">
        <NavItem to="/app/sites" icon={Building2} label="Sites" />
        <NavItem to="/app/team" icon={Users} label="Team Management" />
        <NavItem to="/app/labour" icon={Users} label="Labour" />
        <NavItem to="/app/labour/wallet" icon={Wallet} label="Labour Wallet" />
        <NavItem to="/app/materials" icon={Package} label="Materials" />
        <NavItem to="/app/vendors" icon={Building} label="Vendors" />
        <NavItem to="/app/reports" icon={FileText} label="Daily Reports" />
      </NavGroup>
      <NavGroup title="Finance">
        <NavItem to="/app/payments" icon={BadgeIndianRupee} label="Payments" />
        <NavItem to="/app/expenses" icon={Receipt} label="Expenses" />
      </NavGroup>
      <NavGroup title="Planning">
        <NavItem to="/app/estimates" icon={Calculator} label="Estimator" />
        <NavItem to="/app/boq" icon={FileText} label="BOQ" />
      </NavGroup>
      <NavGroup title="Account">
        <NavItem to="/app/notifications" icon={Bell} label="Notifications" />
        <NavItem to="/app/subscription" icon={CreditCard} label="Subscription" />
        <NavItem to="/app/settings" icon={SettingsIcon} label="Settings" />
      </NavGroup>
    </>
  );

  const supervisorNav = (
    <>
      <NavItem to="/app/dashboard" icon={LayoutDashboard} label="Dashboard" />
      <NavItem to="/app/sites" icon={Building2} label="My Sites" />
      <NavItem to="/app/labour" icon={Users} label="Attendance" />
      <NavItem to="/app/labour/wallet" icon={Wallet} label="Labour Wallet" />
      <NavItem to="/app/materials" icon={Package} label="Materials" />
      <NavItem to="/app/expenses" icon={Receipt} label="Expenses" />
      <NavItem to="/app/reports" icon={FileText} label="Daily Reports" />
      <NavItem to="/app/notifications" icon={Bell} label="Notifications" />
      <NavItem to="/app/settings" icon={SettingsIcon} label="Settings" />
    </>
  );

  const clientNav = (
    <>
      <NavItem to="/app/dashboard" icon={LayoutDashboard} label="Dashboard" />
      <NavItem to="/app/sites" icon={Building2} label="My Project" />
      <NavItem to="/app/payments" icon={Wallet} label="Payments" />
      <NavItem to="/app/reports" icon={FileText} label="Updates" />
      <NavItem to="/app/notifications" icon={Bell} label="Notifications" />
      <NavItem to="/app/settings" icon={SettingsIcon} label="Settings" />
    </>
  );

  const adminNav = (
    <NavGroup title="Platform">
      <NavItem to="/app/admin" icon={LayoutDashboard} label="Overview" end />
      <NavItem to="/app/admin/applications" icon={Briefcase} label="Applications" badge={pendingApps > 0 ? pendingApps : null} />
      <NavItem to="/app/admin/contractors" icon={Users} label="Contractors" />
      <NavItem to="/app/admin/supervisors" icon={Users} label="Supervisors" />
      <NavItem to="/app/admin/subscriptions" icon={CreditCard} label="Subscriptions" />
      <NavItem to="/app/admin/payments" icon={BadgeIndianRupee} label="UPI Payments" />
      <NavItem to="/app/admin/revenue" icon={BarChart3} label="Analytics" />
      <NavItem to="/app/admin/audit" icon={Activity} label="Audit Logs" />
      <NavItem to="/app/notifications" icon={Bell} label="Notifications" />
      <NavItem to="/app/settings" icon={SettingsIcon} label="Settings" />
    </NavGroup>
  );

  const navByRole =
    role === "SUPER_ADMIN" ? adminNav :
      role === "SUPERVISOR" ? supervisorNav :
        role === "CLIENT" ? clientNav :
          contractorNav;

  const initials = (user?.full_name || user?.email || "U").slice(0, 2).toUpperCase();

  const Sidebar = (
    <aside className="flex flex-col w-64 bg-[#171717] text-white border-r border-[#262626] h-screen overflow-y-auto">
      <Link to="/" className="flex items-center gap-2 px-5 h-16 border-b border-white/5 shrink-0" onClick={closeMobile}>
        <div className="flex h-9 w-9 items-center justify-center rounded-lg bg-[#F97316]"><HardHat className="h-5 w-5" /></div>
        <span className="font-display text-base font-extrabold">Site Seva <span className="text-[#F97316]">Pro</span></span>
      </Link>
      <div className="px-3 py-3 flex flex-col gap-1 flex-1" onClick={closeMobile}>
        {role === "CONTRACTOR" && (
          <div className="mx-3 mb-4 rounded-2xl bg-[#262626] p-4 border border-white/5">
            <div className="text-xs text-gray-400">
              Company
            </div>

            <div className="font-bold text-white mt-1">
              {user?.company_name}
            </div>

            <div className="text-xs text-gray-500 mt-2">
              Contractor Account
            </div>
          </div>
        )}
        {role === "SUPER_ADMIN" && (
          <div className="px-3 py-2 mb-1 rounded-lg bg-[#F97316]/10 border border-[#F97316]/20 flex items-center gap-2 text-xs font-semibold uppercase tracking-wider text-[#F97316]">
            <Shield className="h-3.5 w-3.5" /> Super Admin
          </div>
        )}
        {navByRole}
      </div>
      {role === "CONTRACTOR" && (
        <div className="p-3">
          <button
            onClick={() => nav("/app/sites")}
            className="w-full bg-[#F97316] hover:bg-[#EA580C] text-white rounded-xl py-3 font-semibold"
          >
            + Create New Site
          </button>
        </div>
      )}
      <div className="p-3 border-t border-white/5 shrink-0">
        <button onClick={() => { logout(); nav("/login"); }} className="ss-sidebar-link w-full" data-testid="sidebar-logout">
          <LogOut className="h-4 w-4" /> Logout
        </button>
      </div>
    </aside>
  );

  return (
    <div className={`min-h-screen flex ${theme === "dark" ? "ss-dark" : ""}`}>
      {/* Desktop sidebar */}
      <div className="hidden lg:flex sticky top-0 h-screen">{Sidebar}</div>

      {/* Mobile sidebar drawer */}
      {mobileOpen && (
        <div className="fixed inset-0 z-50 lg:hidden">
          <div className="absolute inset-0 bg-black/60" onClick={closeMobile} />
          <div className="absolute left-0 top-0 bottom-0">{Sidebar}</div>
        </div>
      )}

      <div className="flex-1 flex flex-col min-w-0 bg-[var(--ss-main-bg,#F3F4F6)]">
        <header className="sticky top-0 z-30 ss-glass border-b border-gray-200/60 h-16 flex items-center px-4 sm:px-6 gap-3">
          <button className="lg:hidden p-2 rounded-lg hover:bg-gray-100" onClick={() => setMobileOpen(true)} aria-label="Menu" data-testid="header-menu">
            <Menu className="h-5 w-5" />
          </button>
          <div className="hidden md:flex flex-col">
            <span className="font-semibold text-[#171717]">
              {user?.company_name || "Site Seva Pro"}
            </span>

            <span className="text-xs text-gray-500 capitalize">
              {loc.pathname
                .split("/")
                .filter(Boolean)
                .slice(-1)[0]
                ?.replace("-", " ")}
            </span>
          </div>
          <div className="flex-1 max-w-md hidden md:flex">
            <div className="relative w-full">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
              <input className="ss-input pl-9" placeholder="Search sites, labour, materials…" data-testid="header-search" />
            </div>
          </div>
          <button onClick={toggle} className="p-2 rounded-lg hover:bg-gray-100" aria-label="Toggle theme" data-testid="header-theme">
            {theme === "dark" ? <Sun className="h-5 w-5 text-gray-600" /> : <Moon className="h-5 w-5 text-gray-600" />}
          </button>
          <Link
            to="/app/notifications"
            className="relative p-2 rounded-lg hover:bg-gray-100"
          >
            <Bell className="h-5 w-5 text-gray-600" />

            <span className="absolute top-1 right-1 h-2 w-2 bg-red-500 rounded-full" />
          </Link>
          <DropdownMenu>
            <DropdownMenuTrigger asChild>
              <button className="flex items-center gap-2 p-1.5 rounded-lg hover:bg-gray-100" data-testid="header-user-menu">
                <Avatar className="h-8 w-8"><AvatarFallback className="bg-[#171717] text-white text-xs font-bold">{initials}</AvatarFallback></Avatar>
                <div className="hidden md:flex flex-col items-start leading-tight">
                  <span className="text-xs font-semibold text-[#171717]">{user?.full_name}</span>
                  <span className="text-[10px] text-gray-500">{user?.role?.replace("_", " ")}</span>
                </div>
                <ChevronDown className="h-4 w-4 text-gray-500" />
              </button>
            </DropdownMenuTrigger>
            <DropdownMenuContent align="end" className="w-56">
              <DropdownMenuLabel>{user?.email}</DropdownMenuLabel>
              <DropdownMenuSeparator />
              <DropdownMenuItem onClick={() => nav("/app/settings")} data-testid="menu-settings">Settings</DropdownMenuItem>
              {role === "CONTRACTOR" && <DropdownMenuItem onClick={() => nav("/app/subscription")} data-testid="menu-subscription">Subscription</DropdownMenuItem>}
              <DropdownMenuSeparator />
              <DropdownMenuItem onClick={() => { logout(); nav("/login"); }} data-testid="menu-logout">Logout</DropdownMenuItem>
            </DropdownMenuContent>
          </DropdownMenu>
        </header>
        <main className="flex-1 p-4 sm:p-6 lg:p-8">
          <Outlet />
        </main>
      </div>
    </div>
  );
}
