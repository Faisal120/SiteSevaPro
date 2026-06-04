import React from "react";
import { Outlet, NavLink, Link, useNavigate, useLocation } from "react-router-dom";
import {
  LayoutDashboard, Building2, Users, Package, Wallet, FileText, Bell, CreditCard, Settings as SettingsIcon,
  HardHat, LogOut, Shield, Briefcase, BarChart3, ChevronDown, Search,
} from "lucide-react";
import { useAuth } from "@/lib/auth";
import { Avatar, AvatarFallback } from "@/components/ui/avatar";
import {
  DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuLabel, DropdownMenuSeparator, DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";

function NavItem({ to, icon: Icon, label, end }) {
  return (
    <NavLink
      to={to}
      end={end}
      className={({ isActive }) => `ss-sidebar-link ${isActive ? "ss-sidebar-link-active" : ""}`}
      data-testid={`sidebar-${label.toLowerCase().replace(/\s+/g, "-")}`}
    >
      <Icon className="h-4 w-4" />
      <span>{label}</span>
    </NavLink>
  );
}

export default function DashboardLayout() {
  const { user, logout } = useAuth();
  const nav = useNavigate();
  const loc = useLocation();

  const role = user?.role;

  const contractorNav = (
    <>
      <NavItem to="/app/dashboard" icon={LayoutDashboard} label="Dashboard" />
      <NavItem to="/app/sites" icon={Building2} label="Sites" />
      <NavItem to="/app/labour" icon={Users} label="Labour" />
      <NavItem to="/app/materials" icon={Package} label="Materials" />
      <NavItem to="/app/payments" icon={Wallet} label="Payments" />
      <NavItem to="/app/reports" icon={FileText} label="Reports" />
      <NavItem to="/app/notifications" icon={Bell} label="Notifications" />
      <NavItem to="/app/subscription" icon={CreditCard} label="Subscription" />
      <NavItem to="/app/settings" icon={SettingsIcon} label="Settings" />
    </>
  );

  const supervisorNav = (
    <>
      <NavItem to="/app/dashboard" icon={LayoutDashboard} label="Dashboard" />
      <NavItem to="/app/sites" icon={Building2} label="My Sites" />
      <NavItem to="/app/labour" icon={Users} label="Attendance" />
      <NavItem to="/app/materials" icon={Package} label="Materials" />
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
    <>
      <NavItem to="/app/admin" icon={LayoutDashboard} label="Overview" end />
      <NavItem to="/app/admin/applications" icon={Briefcase} label="Applications" />
      <NavItem to="/app/admin/contractors" icon={Users} label="Contractors" />
      <NavItem to="/app/admin/revenue" icon={BarChart3} label="Revenue" />
      <NavItem to="/app/notifications" icon={Bell} label="Notifications" />
      <NavItem to="/app/settings" icon={SettingsIcon} label="Settings" />
    </>
  );

  const navByRole =
    role === "SUPER_ADMIN" ? adminNav :
    role === "SUPERVISOR" ? supervisorNav :
    role === "CLIENT" ? clientNav :
    contractorNav;

  const initials = (user?.full_name || user?.email || "U").slice(0, 2).toUpperCase();

  return (
    <div className="min-h-screen flex bg-[#F3F4F6]">
      {/* Sidebar */}
      <aside className="hidden lg:flex flex-col w-64 bg-[#171717] text-white border-r border-[#262626] sticky top-0 h-screen">
        <Link to="/" className="flex items-center gap-2 px-5 h-16 border-b border-white/5">
          <div className="flex h-9 w-9 items-center justify-center rounded-lg bg-[#F97316]">
            <HardHat className="h-5 w-5" />
          </div>
          <span className="font-display text-base font-extrabold">Site Seva <span className="text-[#F97316]">Pro</span></span>
        </Link>
        <div className="px-3 py-4 flex flex-col gap-1 overflow-y-auto">
          {role === "SUPER_ADMIN" && (
            <div className="px-3 py-2 mb-2 rounded-lg bg-[#F97316]/10 border border-[#F97316]/20 flex items-center gap-2 text-xs font-semibold uppercase tracking-wider text-[#F97316]">
              <Shield className="h-3.5 w-3.5" /> Super Admin
            </div>
          )}
          {navByRole}
        </div>
        <div className="mt-auto p-3 border-t border-white/5">
          <button
            onClick={() => { logout(); nav("/login"); }}
            className="ss-sidebar-link w-full"
            data-testid="sidebar-logout"
          >
            <LogOut className="h-4 w-4" /> Logout
          </button>
        </div>
      </aside>

      {/* Main */}
      <div className="flex-1 flex flex-col min-w-0">
        <header className="sticky top-0 z-30 ss-glass border-b border-gray-200/60 h-16 flex items-center px-4 sm:px-6 gap-4">
          <div className="hidden md:flex items-center gap-2 text-sm text-gray-500">
            <span className="font-medium text-[#171717]">{user?.company_name || "Site Seva Pro"}</span>
            <span>/</span>
            <span className="capitalize">{loc.pathname.split("/").filter(Boolean).slice(-1)[0]?.replace("-", " ")}</span>
          </div>
          <div className="flex-1 max-w-md hidden md:flex">
            <div className="relative w-full">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
              <input
                className="ss-input pl-9"
                placeholder="Search sites, labour, materials…"
                data-testid="header-search"
              />
            </div>
          </div>
          <Link to="/app/notifications" className="relative p-2 rounded-lg hover:bg-gray-100" data-testid="header-notifications">
            <Bell className="h-5 w-5 text-gray-600" />
          </Link>
          <DropdownMenu>
            <DropdownMenuTrigger asChild>
              <button className="flex items-center gap-2 p-1.5 rounded-lg hover:bg-gray-100" data-testid="header-user-menu">
                <Avatar className="h-8 w-8">
                  <AvatarFallback className="bg-[#171717] text-white text-xs font-bold">{initials}</AvatarFallback>
                </Avatar>
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
              {role === "CONTRACTOR" && (
                <DropdownMenuItem onClick={() => nav("/app/subscription")} data-testid="menu-subscription">Subscription</DropdownMenuItem>
              )}
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
