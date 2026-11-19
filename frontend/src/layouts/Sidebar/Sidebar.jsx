import React from "react";
import { Link, useNavigate } from "react-router-dom";
import { Building2 } from "lucide-react";

import CompanyCard from "./CompanyCard";
import NavGroup from "./NavGroup";
import NavItem from "./NavItem";
import SidebarFooter from "./SidebarFooter";

import {
  contractorMenu,
  supervisorMenu,
  clientMenu,
  adminMenu,
} from "./sidebarConfig";

export default function Sidebar({
  role,
  user,
  logout,
  mobileOpen,
  stats,
  setMobileOpen,
  branding,
  subscription,
}) {
  const nav = useNavigate();

  const menu =
    role === "CONTRACTOR"
      ? contractorMenu
      : role === "SUPERVISOR"
        ? supervisorMenu
        : role === "CLIENT"
          ? clientMenu
          : adminMenu;

  return (
    <aside
      className={`
        fixed
        left-0
        top-0
        bottom-0
        z-50

        w-[264px]

        bg-[#090a0c]
        border-r
        border-[#25272c]

        flex
        flex-col

        transition-transform
        duration-300

        ${mobileOpen
          ? "translate-x-0"
          : "-translate-x-full lg:translate-x-0"
        }
      `}
    >
      {/* ================= Logo ================= */}

      <div
        className="
          shrink-0
          min-h-[104px]

          border-b
          border-[#25272c]

          px-5 py-4

          flex
          items-center
          justify-between
        "
      >
        <Link
          to="/app/dashboard"
          onClick={() => setMobileOpen(false)}
          className="flex min-w-0 items-center gap-3"
        >
          <div
            className="
              h-11
              w-11
              rounded-xl
              bg-[#3b82f6]
              shadow-lg
              shadow-blue-950/40

              flex
              items-center
              justify-center
            "
          >
            {branding?.logo_url ? <img src={branding.logo_url} alt="Company logo" className="h-full w-full rounded-xl object-contain bg-white p-1" /> : <Building2 size={22} className="text-white" />}
          </div>

          <div className="min-w-0">

            <h2 className="
                font-display
                line-clamp-2 text-[16px]
                font-bold
                tracking-tight
                text-white
                ">

              {branding?.company_name || user?.company_name || "SiteSeva Pro"}

            </h2>

            <p className="mt-0.5 truncate text-xs text-slate-400">

              {branding?.website || "Construction workspace"}

            </p>

          </div>

        </Link>
      </div>

      {/* =============== Scroll Area =============== */}

      <div
        className="
          flex-1

          overflow-y-auto

          ss-sidebar-scroll
        "
      >
        <div className="px-3 py-4">

          {/* Company */}

          {role === "CONTRACTOR" && (
            <div className="mt-5">
              <CompanyCard user={user} stats={stats} branding={branding} subscription={subscription} />
            </div>
          )}

          {/* Navigation */}

          <div className="mt-5 space-y-8">

            {menu.map((group) => (
              <NavGroup
                key={group.title}
                title={group.title}
              >
                {group.items.map((item) => (
                  <NavItem
                    key={item.path}
                    to={item.path}
                    icon={item.icon}
                    label={item.label}
                    badge={item.badge}
                    end={item.end}
                    onClick={() => setMobileOpen(false)}
                  />
                ))}
              </NavGroup>
            ))}

          </div>

          {/* Footer */}

          <div className="mt-10">

            <SidebarFooter
              logout={logout}

            />

          </div>

          {/* Version */}

          <div
            className="
            mt-8
            pb-6
            text-center
            text-[11px]
            font-medium
            tracking-wide
            text-slate-500
            "
          >
            SiteSeva Pro · Workspace

          </div>

        </div>

      </div>

    </aside>
  );
} 
