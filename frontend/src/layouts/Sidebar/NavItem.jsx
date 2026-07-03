import React from "react";
import { NavLink } from "react-router-dom";

export default function NavItem({
  to,
  icon: Icon,
  label,
  badge,
  end = false,
  onClick,
}) {
  return (
    <NavLink
      to={to}
      end={end}
      onClick={onClick}
      className={({ isActive }) =>
        `
        group
        relative
        flex
        items-center
        gap-3
        h-12
        px-4
        rounded-2xl
        transition-all
        duration-300
        ${
          isActive
            ? "bg-gradient-to-r from-blue-600 to-blue-700 text-white shadow-lg"
            : "text-slate-300 hover:bg-slate-800 hover:text-white"
        }
      `
      }
    >
      {/* Active Indicator */}
      <span
        className={({ isActive }) =>
          isActive
            ? "absolute left-0 top-2 bottom-2 w-1 rounded-r-full bg-white"
            : ""
        }
      />

      {/* Icon */}
      <Icon
        size={20}
        className="
          transition-transform
          duration-300
          group-hover:scale-110
          shrink-0
        "
      />

      {/* Label */}
      <span
        className="
          flex-1
          text-sm
          font-medium
          truncate
        "
      >
        {label}
      </span>

      {/* Badge */}
      {badge && (
        <span
          className="
            text-[10px]
            font-semibold
            uppercase
            rounded-full
            bg-orange-500
            text-white
            px-2
            py-0.5
          "
        >
          {badge}
        </span>
      )}
    </NavLink>
  );
}