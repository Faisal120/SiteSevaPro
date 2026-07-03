import React from "react";
import { Link } from "react-router-dom";
import { HardHat } from "lucide-react";

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
  nav,
  closeMobile,
}) {
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
      className="
        w-72
        bg-[#020817]
        border-r
        border-slate-800
        text-white
        flex
        flex-col
        h-screen
        overflow-y-auto
      "
    >
      {/* ================= LOGO ================= */}

      <Link
        to="/"
        onClick={closeMobile}
        className="
          flex
          items-center
          gap-4
          px-6
          h-20
          border-b
          border-slate-800
          shrink-0
        "
      >
        <div
          className="
            h-12
            w-12
            rounded-2xl
            bg-gradient-to-br
            from-blue-600
            to-blue-800
            flex
            items-center
            justify-center
            shadow-xl
          "
        >
          <HardHat
            size={26}
            className="text-white"
          />
        </div>

        <div>

          <h2
            className="
              text-xl
              font-bold
              tracking-tight
            "
          >
            SiteSeva
          </h2>

          <p
            className="
              text-xs
              uppercase
              tracking-[0.22em]
              text-slate-400
            "
          >
            Construction OS
          </p>

        </div>

      </Link>

      {/* ================= COMPANY ================= */}

      {role === "CONTRACTOR" && (
        <CompanyCard
          user={user}
        />
      )}

      {/* ================= NAVIGATION ================= */}

      <nav
        className="
          flex-1
          px-3
          pb-6
        "
      >
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
                onClick={closeMobile}
              />
            ))}
          </NavGroup>
        ))}
      </nav>

      {/* ================= FOOTER ================= */}

      <SidebarFooter
        logout={logout}
        nav={nav}
      />
    </aside>
  );
}