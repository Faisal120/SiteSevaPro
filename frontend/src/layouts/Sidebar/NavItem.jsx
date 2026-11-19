import React from "react";
import { NavLink } from "react-router-dom";
import { ChevronRight } from "lucide-react";

export default function NavItem({
  to,
  icon: Icon,
  label,
  badge,
  end = false,
  onClick,
}) {
  return (
    <NavLink to={to} end={end} onClick={onClick}>
      {({ isActive }) => (
        <div
          className={`
            group
            relative

            flex
            items-center

            h-10

            rounded-xl

            px-3

            transition-all
            duration-200

            ${isActive
              ? `
                    bg-[#1d2025]
                    text-white
                    border
                    border-[#30323a]
                  `
              : `
                    text-slate-400
                    hover:bg-[#17191d]
                    hover:text-white
                  `
            }
          `}
        >
          {/* Active Indicator */}

          {isActive && (
            <span
              className="
                absolute
                left-0
                top-2
                bottom-2

                w-1

                rounded-r-full

                bg-[#3b82f6]
              "
            />
          )}

          {/* Icon */}

          <Icon
            size={18}
            strokeWidth={2}
            className={`
                shrink-0
                transition-all
                duration-200

                ${isActive
                ? "text-white"
                : "text-slate-500 group-hover:text-white"
              }
            `}
          />

          {/* Label */}

          <span
            className="
              ml-3

              flex-1

              truncate

              text-[14px]

              font-medium
            "
          >
            {label}
          </span>

          {/* Badge */}

          {badge && (
            <span
              className={`
                rounded-full

                px-2
                py-0.5

                text-[10px]

                font-semibold

                ${isActive
                  ? "bg-white/20 text-white"
                  : "bg-blue-500/15 text-blue-300"
                }
              `}
            >
              {badge}
            </span>
          )}

          {/* Arrow */}

          {!badge && (
            <ChevronRight
              size={15}
              className={`
                transition-all

                ${isActive
                  ? "opacity-100"
                  : "opacity-0 group-hover:opacity-40"
                }
              `}
            />
          )}
        </div>
      )}
    </NavLink>
  );
}
