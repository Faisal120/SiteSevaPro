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

        w-[280px]

        bg-[#0B1120]
        border-r
        border-slate-700/70

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
          h-24

          border-b
          border-slate-800

          px-7

          flex
          items-center
          justify-between
        "
      >
        <Link
          to="/app/dashboard"
          onClick={() => setMobileOpen(false)}
          className="flex items-center gap-3"
        >
          <div
            className="
              h-14
              w-14
              rounded-2xl
              bg-gradient-to-br
              from-blue-600
              to-indigo-700
              shadow-lg
              shadow-blue-900/30

              flex
              items-center
              justify-center
            "
          >
            <Building2
              size={22}
              className="text-white"
            />
          </div>

          <div>

            <h2 className="
                font-display
                text-[20px]
                font-bold
                tracking-tight
                text-white
                ">

              SiteSeva Pro

            </h2>

            <p className="text-xs text-slate-400">

              Enterprise Edition

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
        <div className="px-4 py-4">

          {/* Company */}

          {role === "CONTRACTOR" && (
            <div className="mt-5">
              <CompanyCard user={user} stats={stats} />
            </div>
          )}

          {/* Navigation */}

          <div className="mt-6 space-y-10">

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
            SiteSeva Pro v3 Preview

          </div>

        </div>

      </div>

    </aside>
  );
} 