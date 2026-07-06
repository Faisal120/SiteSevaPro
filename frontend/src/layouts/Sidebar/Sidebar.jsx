import React from "react";
import { Link, useNavigate } from "react-router-dom";
import { Plus, Building2 } from "lucide-react";

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

        w-[260px]

        bg-slate-950
        border-r
        border-slate-800

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
          h-20

          border-b
          border-slate-800

          px-6

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
              h-11
              w-11

              rounded-xl

              bg-blue-600

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

            <h2 className="font-bold text-white text-lg">

              SiteSeva Pro

            </h2>

            <p className="text-xs text-slate-400">

              Construction OS

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
        <div className="px-3 py-2">

          {/* Company */}

          {role === "CONTRACTOR" && (
            <div className="mt-5">
              <CompanyCard user={user} />
            </div>
          )}

          {/* Navigation */}

          <div className="mt-6 space-y-8">

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

          <div className="mt-8">

            <SidebarFooter
              logout={logout}

            />

          </div>

          {/* Version */}

          <div
            className="
              mt-8

              text-center

              text-xs

              text-slate-500
            "
          >
            Version 2.0.0

          </div>

        </div>

      </div>

    </aside>
  );
} 